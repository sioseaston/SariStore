import { NextRequest, NextResponse } from 'next/server';
import { db, StoreRow } from '@/lib/db';
import { issueToken } from '@/lib/licenseSigner';

/**
 * POST /api/license/check-status
 * Body: { store_id: string, device_id: string }
 *
 * Called whenever the app has connectivity and needs to renew/validate:
 *  - subscription stores: every ~30 days when the local token expires
 *  - lifetime stores: opportunistically (e.g. on app update), to catch a
 *    remote disable — enforcement is inherently weak here since it only
 *    fires if the device happens to reconnect and call this endpoint.
 */
export async function POST(req: NextRequest) {
  const body = await req.json().catch(() => null);
  const storeId = body?.store_id as string | undefined;
  const deviceId = body?.device_id as string | undefined;

  if (!storeId || !deviceId) {
    return NextResponse.json(
      { code: 'invalid_request', message: 'store_id and device_id are required' },
      { status: 400 },
    );
  }

  const { data: store, error } = await db
    .from('stores')
    .select('*')
    .eq('id', storeId)
    .single<StoreRow>();

  if (error || !store) {
    return NextResponse.json({ code: 'not_found', message: 'Store not found' }, { status: 404 });
  }

  if (store.device_id !== deviceId) {
    return NextResponse.json(
      { code: 'device_mismatch', message: 'This device is not authorized for this store.' },
      { status: 409 },
    );
  }

  if (store.status === 'disabled' || store.status === 'deleted') {
    return NextResponse.json(
      { code: 'disabled', message: 'This store has been disabled. Contact the developer to resolve.' },
      { status: 403 },
    );
  }

  // Subscription-specific payment gate. Lifetime stores skip this entirely
  // since they're paid in full at activation.
  if (store.license_type === 'subscription') {
    const dueDate = store.due_date ? new Date(store.due_date) : null;
    const now = new Date();
    const isPastDue = dueDate !== null && now > dueDate && store.amount_due > 0;

    if (isPastDue) {
      return NextResponse.json(
        {
          code: 'unpaid',
          message: `Payment of ₱${store.amount_due} is due. Please settle with the developer to continue.`,
          amount_due: store.amount_due,
        },
        { status: 402 },
      );
    }
  }

  // status === 'paused' still issues a fresh token (soft warning shown
  // client-side), unlike 'disabled' which hard-blocks above.
  const { token_json } = issueToken({
    storeId: store.id,
    licenseType: store.license_type,
    cycleDays: store.cycle_days,
  });

  await db.from('stores').update({ last_login_check: new Date().toISOString() }).eq('id', store.id);

  return NextResponse.json({ token: token_json, status: store.status }, { status: 200 });
}
