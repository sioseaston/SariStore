'use client';

import { useEffect, useState, useCallback } from 'react';
import Link from 'next/link';
import type { StoreRow } from '@/lib/db';
import StoreStatusBadge from '@/components/StoreStatusBadge';
import PaymentForm from '@/components/PaymentForm';

interface PaymentRow {
  id: string;
  amount: number;
  method: string;
  notes: string | null;
  payment_date: string;
}

export default function StoreDetailPage({ params }: { params: { storeId: string } }) {
  const [store, setStore] = useState<StoreRow | null>(null);
  const [payments, setPayments] = useState<PaymentRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionError, setActionError] = useState<string | null>(null);
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    const res = await fetch(`/api/stores/${params.storeId}`);
    if (res.ok) {
      const body = await res.json();
      setStore(body.store);
      setPayments(body.payments);
    }
    setLoading(false);
  }, [params.storeId]);

  useEffect(() => {
    load();
  }, [load]);

  async function runAction(action: 'pause' | 'disable' | 'reactivate' | 'delete') {
    if (action === 'delete') {
      const confirmed = window.confirm(
        'This soft-deletes the store (status set to deleted). Sales history is kept. Continue?',
      );
      if (!confirmed) return;
    }
    setActionLoading(action);
    setActionError(null);

    const res = await fetch(`/api/stores/${params.storeId}/${action}`, { method: 'POST' });
    setActionLoading(null);

    if (!res.ok) {
      const body = await res.json().catch(() => ({}));
      setActionError(body.message ?? `Failed to ${action} store`);
      return;
    }
    load();
  }

  if (loading) {
    return <div className="max-w-3xl mx-auto px-6 py-12 text-sm text-gray-500">Loading...</div>;
  }

  if (!store) {
    return <div className="max-w-3xl mx-auto px-6 py-12 text-sm text-red-600">Store not found.</div>;
  }

  return (
    <div className="max-w-3xl mx-auto px-6 py-8">
      <Link href="/dashboard" className="text-sm text-gray-500 hover:text-gray-800">
        ← Back to Stores
      </Link>

      <div className="flex items-start justify-between mt-2 mb-6">
        <div>
          <h1 className="text-2xl font-semibold">{store.store_name}</h1>
          <p className="text-sm text-gray-500 mt-1">
            {store.owner_name ?? '—'} · {store.contact_number ?? 'no contact number'}
          </p>
        </div>
        <StoreStatusBadge status={store.status} />
      </div>

      <div className="grid grid-cols-2 gap-4 mb-6">
        <InfoCard label="License Type" value={store.license_type} capitalize />
        <InfoCard label="Amount Due" value={store.amount_due > 0 ? `₱${store.amount_due.toLocaleString()}` : '₱0'} />
        <InfoCard
          label="Due Date"
          value={store.due_date ? new Date(store.due_date).toLocaleDateString() : '—'}
        />
        <InfoCard
          label="Last Payment"
          value={store.last_payment_date ? new Date(store.last_payment_date).toLocaleDateString() : '—'}
        />
        <InfoCard label="Device Bound" value={store.device_id ? 'Yes' : 'Not activated yet'} />
        <InfoCard label="Cycle Length" value={`${store.cycle_days} days`} />
      </div>

      <section className="bg-white border border-gray-200 rounded-lg p-5 mb-6">
        <h2 className="text-sm font-semibold mb-3">Store Actions</h2>
        <div className="flex flex-wrap gap-2">
          {store.status !== 'active' && (
            <ActionButton
              label="Reactivate"
              color="green"
              loading={actionLoading === 'reactivate'}
              onClick={() => runAction('reactivate')}
            />
          )}
          {store.status === 'active' && (
            <ActionButton
              label="Pause"
              color="amber"
              loading={actionLoading === 'pause'}
              onClick={() => runAction('pause')}
            />
          )}
          {store.status !== 'disabled' && (
            <ActionButton
              label="Disable"
              color="red"
              loading={actionLoading === 'disable'}
              onClick={() => runAction('disable')}
            />
          )}
          {store.status !== 'deleted' && (
            <ActionButton
              label="Delete"
              color="gray"
              loading={actionLoading === 'delete'}
              onClick={() => runAction('delete')}
            />
          )}
        </div>
        {actionError && <p className="text-sm text-red-600 mt-3">{actionError}</p>}
      </section>

      <section className="bg-white border border-gray-200 rounded-lg p-5 mb-6">
        <h2 className="text-sm font-semibold mb-3">Record a Payment</h2>
        <PaymentForm storeId={store.id} onRecorded={load} />
      </section>

      <section className="bg-white border border-gray-200 rounded-lg p-5">
        <h2 className="text-sm font-semibold mb-3">Payment History</h2>
        {payments.length === 0 ? (
          <p className="text-sm text-gray-500">No payments recorded yet.</p>
        ) : (
          <table className="w-full text-sm">
            <thead className="text-left text-gray-500">
              <tr>
                <th className="pb-2 font-medium">Date</th>
                <th className="pb-2 font-medium">Amount</th>
                <th className="pb-2 font-medium">Method</th>
                <th className="pb-2 font-medium">Notes</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {payments.map((p) => (
                <tr key={p.id}>
                  <td className="py-2">{new Date(p.payment_date).toLocaleString()}</td>
                  <td className="py-2">₱{p.amount.toLocaleString()}</td>
                  <td className="py-2 capitalize">{p.method}</td>
                  <td className="py-2 text-gray-500">{p.notes ?? '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </div>
  );
}

function InfoCard({ label, value, capitalize }: { label: string; value: string; capitalize?: boolean }) {
  return (
    <div className="bg-white border border-gray-200 rounded-lg p-4">
      <p className="text-xs text-gray-500 mb-1">{label}</p>
      <p className={`text-sm font-medium ${capitalize ? 'capitalize' : ''}`}>{value}</p>
    </div>
  );
}

const ACTION_COLORS: Record<string, string> = {
  green: 'bg-green-600 hover:bg-green-700',
  amber: 'bg-amber-500 hover:bg-amber-600',
  red: 'bg-red-600 hover:bg-red-700',
  gray: 'bg-gray-500 hover:bg-gray-600',
};

function ActionButton({
  label,
  color,
  loading,
  onClick,
}: {
  label: string;
  color: string;
  loading: boolean;
  onClick: () => void;
}) {
  return (
    <button
      onClick={onClick}
      disabled={loading}
      className={`text-white text-sm font-medium px-4 py-2 rounded-md transition disabled:opacity-50 ${ACTION_COLORS[color]}`}
    >
      {loading ? '...' : label}
    </button>
  );
}
