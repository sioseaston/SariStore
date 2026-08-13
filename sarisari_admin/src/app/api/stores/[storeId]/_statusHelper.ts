import { NextResponse } from 'next/server';
import { db, StoreRow } from '@/lib/db';

export type StoreStatus = 'active' | 'paused' | 'disabled' | 'deleted';

/**
 * Applies a status transition to a store. Shared by the pause/disable/
 * reactivate/delete route handlers so they all behave consistently
 * (soft-update only, never a hard delete of the row — see design notes
 * in the original conversation about preserving sales history).
 */
export async function applyStatusChange(storeId: string, newStatus: StoreStatus) {
  const { data: store, error: fetchError } = await db
    .from('stores')
    .select('*')
    .eq('id', storeId)
    .single<StoreRow>();

  if (fetchError || !store) {
    return NextResponse.json({ message: 'Store not found' }, { status: 404 });
  }

  const { data: updated, error: updateError } = await db
    .from('stores')
    .update({ status: newStatus })
    .eq('id', storeId)
    .select()
    .single<StoreRow>();

  if (updateError || !updated) {
    return NextResponse.json({ message: updateError?.message ?? 'Update failed' }, { status: 500 });
  }

  return NextResponse.json({ store: updated }, { status: 200 });
}
