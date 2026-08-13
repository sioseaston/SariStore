import { NextRequest, NextResponse } from 'next/server';
import { randomBytes } from 'crypto';
import { db, StoreRow } from '@/lib/db';

function generateLicenseKey(): string {
  // e.g. SS-A1B2-C3D4-E5F6
  const part = () => randomBytes(2).toString('hex').toUpperCase();
  return `SS-${part()}-${part()}-${part()}`;
}

/**
 * GET /api/stores
 * Lists all stores for the dashboard's store table. Supports optional
 * ?status= filter.
 */
export async function GET(req: NextRequest) {
  const status = req.nextUrl.searchParams.get('status');

  let query = db.from('stores').select('*').order('created_at', { ascending: false });
  if (status) {
    query = query.eq('status', status);
  }

  const { data, error } = await query;
  if (error) {
    return NextResponse.json({ message: error.message }, { status: 500 });
  }
  return NextResponse.json({ stores: data as StoreRow[] }, { status: 200 });
}

/**
 * POST /api/stores
 * Body: { store_name, owner_name?, contact_number?, license_type,
 *         cycle_days? (subscription only), initial_amount_due? }
 *
 * Creates a new store and generates its license key. The key is returned
 * once here for the admin to copy/send to the owner — it is not otherwise
 * retrievable in plaintext from the dashboard afterward (store it securely
 * if you need to look it up later, or add a "reveal" flow with re-auth).
 */
export async function POST(req: NextRequest) {
  const body = await req.json().catch(() => null);
  const storeName = body?.store_name as string | undefined;
  const licenseType = body?.license_type as 'lifetime' | 'subscription' | undefined;

  if (!storeName || !licenseType) {
    return NextResponse.json(
      { message: 'store_name and license_type are required' },
      { status: 400 },
    );
  }
  if (!['lifetime', 'subscription'].includes(licenseType)) {
    return NextResponse.json({ message: 'license_type must be lifetime or subscription' }, { status: 400 });
  }

  const licenseKey = generateLicenseKey();

  const { data, error } = await db
    .from('stores')
    .insert({
      store_name: storeName,
      owner_name: body?.owner_name ?? null,
      contact_number: body?.contact_number ?? null,
      license_key: licenseKey,
      license_type: licenseType,
      status: 'active',
      cycle_days: body?.cycle_days ?? 30,
      grace_period_days: body?.grace_period_days ?? 3,
      amount_due: body?.initial_amount_due ?? 0,
      // Lifetime stores need activation_verified=true once payment is
      // confirmed out-of-band; leave false until the admin marks it paid.
      activation_verified: licenseType === 'lifetime' ? false : true,
    })
    .select()
    .single<StoreRow>();

  if (error || !data) {
    return NextResponse.json({ message: error?.message ?? 'Failed to create store' }, { status: 500 });
  }

  return NextResponse.json({ store: data, license_key: licenseKey }, { status: 201 });
}
