import { NextRequest, NextResponse } from 'next/server';
import { db, StoreRow } from '@/lib/db';

/**
 * POST /api/stores/[storeId]/extend
 * Body: { days: number, amount?: number, method?: string, notes?: string }
 *
 * Admin action that adds `days` to a subscription store's license. The new
 * due date is computed from the current due_date if it's still in the future
 * (so remaining days are never lost), otherwise from today. Clears amount_due,
 * auto-reactivates paused stores, and logs the action in the payments table
 * (shown as the store's license history).
 */
export async function POST(req: NextRequest, { params }: { params: Promise<{ storeId: string }> }) {
  const { storeId } = await params;
  const body = await req.json().catch(() => null);
  const days = Number(body?.days);
  const amount = body?.amount != null ? Number(body.amount) : 0;
  const method = (body?.method as string | undefined) ?? 'extension';
  const notes = body?.notes as string | undefined;

  if (!Number.isInteger(days) || days <= 0) {
    return NextResponse.json(
      { code: 'invalid_request', message: 'days must be a positive whole number' },
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

  if (store.license_type === 'lifetime') {
    return NextResponse.json(
      { code: 'invalid_request', message: 'Lifetime stores do not expire and cannot be extended.' },
      { status: 400 },
    );
  }

  const now = new Date();
  const currentDue = store.due_date ? new Date(`${store.due_date}T00:00:00`) : null;
  const base = currentDue && currentDue.getTime() > now.getTime() ? currentDue : now;
  const newDueDate = new Date(base.getTime() + days * 24 * 60 * 60 * 1000);

  const { data: updated, error: updateError } = await db
    .from('stores')
    .update({
      due_date: newDueDate.toISOString().slice(0, 10),
      amount_due: 0,
      last_payment_date: now.toISOString().slice(0, 10),
      status: store.status === 'paused' ? 'active' : store.status,
      last_login_check: now.toISOString(),
    })
    .eq('id', store.id)
    .select()
    .single<StoreRow>();

  if (updateError || !updated) {
    return NextResponse.json({ message: updateError?.message ?? 'Failed to extend license' }, { status: 500 });
  }

  await db.from('payments').insert({
    store_id: store.id,
    amount,
    method,
    notes: notes ?? `Extended by ${days} day${days === 1 ? '' : 's'}`,
  });

  return NextResponse.json(
    { store: updated, new_due_date: newDueDate.toISOString().slice(0, 10) },
    { status: 200 },
  );
}