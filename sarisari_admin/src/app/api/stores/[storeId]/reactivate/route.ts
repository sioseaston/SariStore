import { NextRequest } from 'next/server';
import { applyStatusChange } from '../_statusHelper';

/**
 * POST /api/stores/[storeId]/reactivate
 * Manually restores a paused or disabled store to active, independent of
 * payment status (e.g. the admin wants to grant a grace period). For the
 * normal "customer paid" path, prefer /mark-paid, which also updates
 * amount_due and due_date.
 */
export async function POST(_req: NextRequest, { params }: { params: { storeId: string } }) {
  return applyStatusChange(params.storeId, 'active');
}
