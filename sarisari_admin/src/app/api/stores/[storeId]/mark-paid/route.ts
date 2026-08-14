import { NextRequest, NextResponse } from 'next/server';
import { db, StoreRow } from '@/lib/db';

/**
 * POST /api/stores/[storeId]/mark-paid
 * Body: { amount: number, method?: string, notes?: string }
 *
 * Called from the admin dashboard's "Mark as Paid" button. Logs the
 * payment, clears amount_due, and pushes due_date forward by cycle_days.
 * The store itself doesn't unlock until it next calls /check-status —
 * this route only updates the source of truth on the server.
 */
export async function POST(req: NextRequest, { params }: { params: Promise<{ storeId: string }> }) {
  const { storeId } = await params;
  const body = await req.json().catch(() => null);
  const amount = body?.amount as number | undefined;
  const method = (body?.method as string | undefined) ?? 'cash';
  const notes = body?.notes as string | undefined;

  if (!amount || amount <= 0) {
    return NextResponse.json(
      { code: 'invalid_request', message: 'A positive amount is required' },
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

  await db.from('payments').insert({
    store_id: store.id,
    amount,
    method,
    notes: notes ?? null,
  });

  const now = new Date();
  const newDueDate =
    store.license_type === 'subscription'
      ? new Date(now.getTime() + store.cycle_days * 24 * 60 * 60 * 1000)
      : null;

  const remainingDue = Math.max(0, (store.amount_due ?? 0) - amount);

  await db
    .from('stores')
    .update({
      amount_due: remainingDue,
      last_payment_date: now.toISOString(),
      due_date: newDueDate ? newDueDate.toISOString() : store.due_date,
      status: store.status === 'paused' ? 'active' : store.status,
      // For lifetime stores, a first full payment also flips this on so
      // /api/license/activate will allow activation.
      activation_verified: store.license_type === 'lifetime' ? remainingDue === 0 : store.activation_verified,
    })
    .eq('id', store.id);

  return NextResponse.json(
    { message: 'Payment recorded', remaining_due: remainingDue, new_due_date: newDueDate },
    { status: 200 },
  );
}
