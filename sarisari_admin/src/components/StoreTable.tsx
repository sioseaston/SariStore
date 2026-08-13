'use client';

import Link from 'next/link';
import StoreStatusBadge from './StoreStatusBadge';
import type { StoreRow } from '@/lib/db';

export default function StoreTable({ stores }: { stores: StoreRow[] }) {
  if (stores.length === 0) {
    return <p className="text-sm text-gray-500 py-8 text-center">No stores yet.</p>;
  }

  return (
    <div className="overflow-x-auto border border-gray-200 rounded-lg">
      <table className="min-w-full text-sm">
        <thead className="bg-gray-50 text-left text-gray-500">
          <tr>
            <th className="px-4 py-3 font-medium">Store</th>
            <th className="px-4 py-3 font-medium">Plan</th>
            <th className="px-4 py-3 font-medium">Status</th>
            <th className="px-4 py-3 font-medium">Amount Due</th>
            <th className="px-4 py-3 font-medium">Due Date</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-100">
          {stores.map((store) => (
            <tr key={store.id} className="hover:bg-gray-50">
              <td className="px-4 py-3">
                <Link href={`/dashboard/${store.id}`} className="font-medium text-teal-700 hover:underline">
                  {store.store_name}
                </Link>
              </td>
              <td className="px-4 py-3 capitalize text-gray-600">{store.license_type}</td>
              <td className="px-4 py-3">
                <StoreStatusBadge status={store.status} />
              </td>
              <td className="px-4 py-3 text-gray-600">
                {store.amount_due > 0 ? `₱${store.amount_due.toLocaleString()}` : '—'}
              </td>
              <td className="px-4 py-3 text-gray-600">
                {store.due_date ? new Date(store.due_date).toLocaleDateString() : '—'}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
