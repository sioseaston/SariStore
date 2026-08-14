import { NextRequest, NextResponse } from 'next/server';
import { db, StoreRow } from '@/lib/db';

/**
 * GET /api/stores/[storeId]
 * Returns store details plus its payment history, for the store detail page.
 */
export async function GET(_req: NextRequest, { params }: { params: Promise<{ storeId: string }> }) {
  const { storeId } = await params;
  const { data: store, error } = await db
    .from('stores')
    .select('*')
    .eq('id', storeId)
    .single<StoreRow>();

  if (error || !store) {
    return NextResponse.json({ message: 'Store not found' }, { status: 404 });
  }

  const { data: payments } = await db
    .from('payments')
    .select('*')
    .eq('store_id', storeId)
    .order('payment_date', { ascending: false });

  return NextResponse.json({ store, payments: payments ?? [] }, { status: 200 });
}
