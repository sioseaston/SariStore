import { NextRequest } from 'next/server';
import { applyStatusChange } from '../_statusHelper';

/**
 * POST /api/stores/[storeId]/pause
 * Soft warning state — subscription stores keep working with a banner,
 * checkout/inventory edits are NOT blocked (see status behavior table in
 * the system design). Typically used for "payment is a few days late,
 * please resolve soon" rather than a hard cutoff.
 */
export async function POST(_req: NextRequest, { params }: { params: Promise<{ storeId: string }> }) {
  const { storeId } = await params;
  return applyStatusChange(storeId, 'paused');
}
