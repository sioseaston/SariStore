import { NextRequest } from 'next/server';
import { applyStatusChange } from '../_statusHelper';

/**
 * POST /api/stores/[storeId]/disable
 * Hard lock. Takes effect on this store's next successful license
 * check-in (immediately for subscription stores, which check in every
 * cycle; only if/when a lifetime-store device happens to reconnect,
 * per the lifetime enforcement tradeoff described in the system design).
 */
export async function POST(_req: NextRequest, { params }: { params: Promise<{ storeId: string }> }) {
  const { storeId } = await params;
  return applyStatusChange(storeId, 'disabled');
}
