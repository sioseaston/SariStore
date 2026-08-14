import { NextRequest, NextResponse } from 'next/server';
import { db, StoreRow } from '@/lib/db';

/**
 * POST /api/stores/[storeId]/convert-lifetime
 *
 * Upgrades a subscription store to a permanent (lifetime) license. Clears the
 * due date and amount due, verifies activation, auto-reactivates paused
 * stores, and logs the upgrade. Takes effect on the store's next license
 * check-in, which then issues a non-expiring token.
 */
export async function POST(_req: NextRequest, { params }: { params: Promise<{ storeId: string }> }) {
  const { storeId } = await params;

  const { data: store, error } = await db
    .from('stores')
    .select('*')
    .eq('id', storeId)
    .single<StoreRow>();

  if (error || !store) {
    return NextResponse.json({ code: 'not_found', message: 'Store not found' }, { status: 404 });
  }

  if (store.license_type === 'lifetime') {
    return NextResponse.json(
      { code: 'invalid_request', message: 'This store is already on a lifetime license.' },
      { status: 400 },
    );
  }

  const now = new Date();

  const { data: updated, error: updateError } = await db
    .from('stores')
    .update({
      license_type: 'lifetime',
      due_date: null,
      amount_due: 0,
      activation_verified: true,
      status: store.status === 'paused' ? 'active' : store.status,
      last_payment_date: now.toISOString().slice(0, 10),
      last_login_check: now.toISOString(),
    })
    .eq('id', store.id)
    .select()
    .single<StoreRow>();

  if (updateError || !updated) {
    return NextResponse.json(
      { message: updateError?.message ?? 'Failed to convert store to lifetime' },
      { status: 500 },
    );
  }

  await db.from('payments').insert({
    store_id: store.id,
    amount: 0,
    method: 'lifetime_upgrade',
    notes: 'Converted to permanent license',
  });

  return NextResponse.json({ store: updated }, { status: 200 });
}