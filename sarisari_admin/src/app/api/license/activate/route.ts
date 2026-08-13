import { NextRequest, NextResponse } from 'next/server';
import { db, StoreRow } from '@/lib/db';
import { issueToken } from '@/lib/licenseSigner';

/**
 * POST /api/license/activate
 * Body: { license_key: string, device_id: string }
 *
 * Called ONCE by the app on first launch (both lifetime and subscription
 * stores). Binds the license key to a device and returns a signed token.
 * Subsequent renewals for subscription stores go through /check-status.
 */
export async function POST(req: NextRequest) {
  const body = await req.json().catch(() => null);
  const licenseKey = body?.license_key as string | undefined;
  const deviceId = body?.device_id as string | undefined;

  if (!licenseKey || !deviceId) {
    return NextResponse.json(
      { code: 'invalid_request', message: 'license_key and device_id are required' },
      { status: 400 },
    );
  }

  const { data: store, error } = await db
    .from('stores')
    .select('*')
    .eq('license_key', licenseKey)
    .single<StoreRow>();

  if (error || !store) {
    return NextResponse.json(
      { code: 'invalid_key', message: 'License key not found' },
      { status: 404 },
    );
  }

  if (store.status === 'disabled' || store.status === 'deleted') {
    return NextResponse.json(
      { code: 'disabled', message: 'This store has been disabled. Contact the developer.' },
      { status: 403 },
    );
  }

  // Device binding: a license key activates exactly one device.
  // If already bound to a different device, reject (prevents key sharing).
  if (store.device_id && store.device_id !== deviceId) {
    return NextResponse.json(
      {
        code: 'device_mismatch',
        message: 'This license is already active on another device. Contact the developer to transfer it.',
      },
      { status: 409 },
    );
  }

  // Lifetime stores must show a completed one-time payment before activating.
  // Subscription stores can activate with amount_due > 0 as long as this is
  // the very first activation (grace period covers the initial cycle) —
  // adjust this rule to match your actual sales flow.
  if (store.license_type === 'lifetime' && !store.activation_verified) {
    return NextResponse.json(
      { code: 'unpaid', message: 'Payment not yet confirmed for this license.' },
      { status: 402 },
    );
  }

  const { token_json } = issueToken({
    storeId: store.id,
    licenseType: store.license_type,
    cycleDays: store.cycle_days,
  });

  await db
    .from('stores')
    .update({
      device_id: deviceId,
      activated_at: new Date().toISOString(),
      last_login_check: new Date().toISOString(),
    })
    .eq('id', store.id);

  return NextResponse.json({ token: token_json }, { status: 200 });
}
