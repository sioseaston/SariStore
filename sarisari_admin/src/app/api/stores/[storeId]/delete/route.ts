import { NextRequest } from 'next/server';
import { applyStatusChange } from '../_statusHelper';

/**
 * POST /api/stores/[storeId]/delete
 * Soft delete only — status flips to 'deleted', the row and all its sales/
 * payment history are kept. Hard-deleting is intentionally not exposed
 * here since it would destroy the owner's records irrecoverably.
 */
export async function POST(_req: NextRequest, { params }: { params: Promise<{ storeId: string }> }) {
  const { storeId } = await params;
  return applyStatusChange(storeId, 'deleted');
}
