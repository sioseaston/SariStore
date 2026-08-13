import Link from 'next/link';
import { db, StoreRow } from '@/lib/db';
import StoreTable from '@/components/StoreTable';
import LogoutButton from '@/components/LogoutButton';

export const dynamic = 'force-dynamic'; // always show fresh store statuses

export default async function DashboardPage() {
  const { data: stores } = await db
    .from('stores')
    .select('*')
    .order('created_at', { ascending: false });

  const rows = (stores ?? []) as StoreRow[];
  const activeCount = rows.filter((s) => s.status === 'active').length;
  const pastDueCount = rows.filter(
    (s) => s.status === 'active' && s.amount_due > 0 && s.due_date && new Date(s.due_date) < new Date(),
  ).length;

  return (
    <div className="max-w-6xl mx-auto px-6 py-8">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-semibold">Stores</h1>
          <p className="text-sm text-gray-500 mt-1">
            {rows.length} total · {activeCount} active
            {pastDueCount > 0 && <span className="text-amber-600"> · {pastDueCount} past due</span>}
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Link
            href="/dashboard/create"
            className="bg-teal-600 hover:bg-teal-700 text-white text-sm font-medium px-4 py-2 rounded-md transition"
          >
            + Create Store
          </Link>
          <LogoutButton />
        </div>
      </div>

      <StoreTable stores={rows} />
    </div>
  );
}
