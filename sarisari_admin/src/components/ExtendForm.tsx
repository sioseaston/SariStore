'use client';

import { useState } from 'react';

export default function ExtendForm({
  storeId,
  cycleDays,
  onExtended,
}: {
  storeId: string;
  cycleDays: number;
  onExtended: () => void;
}) {
  const [days, setDays] = useState(String(cycleDays));
  const [amount, setAmount] = useState('');
  const [method, setMethod] = useState('cash');
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setSuccess(null);

    const res = await fetch(`/api/stores/${storeId}/extend`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        days: Number(days),
        amount: amount ? Number(amount) : undefined,
        method,
        notes: notes || undefined,
      }),
    });

    setLoading(false);

    const body = await res.json().catch(() => ({}));

    if (!res.ok) {
      setError(body.message ?? 'Failed to extend license');
      return;
    }

    setAmount('');
    setNotes('');
    setSuccess(
      `License extended by ${days} day${Number(days) === 1 ? '' : 's'} — new due date ${body.new_due_date}.`,
    );
    onExtended();
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-3">
      <div className="flex gap-3">
        <input
          type="number"
          required
          min="1"
          step="1"
          placeholder="Days to add"
          value={days}
          onChange={(e) => setDays(e.target.value)}
          className="flex-1 border border-gray-300 rounded-md px-3 py-2 text-sm"
        />
        <input
          type="number"
          min="0.01"
          step="0.01"
          placeholder="Amount (₱, optional)"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          className="flex-1 border border-gray-300 rounded-md px-3 py-2 text-sm"
        />
      </div>
      <div className="flex gap-3">
        <select
          value={method}
          onChange={(e) => setMethod(e.target.value)}
          className="border border-gray-300 rounded-md px-3 py-2 text-sm"
        >
          <option value="cash">Cash</option>
          <option value="gcash">GCash</option>
          <option value="bank">Bank Transfer</option>
        </select>
        <input
          placeholder="Notes (optional)"
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          className="flex-1 border border-gray-300 rounded-md px-3 py-2 text-sm"
        />
      </div>
      {error && <p className="text-sm text-red-600">{error}</p>}
      {success && <p className="text-sm text-green-700">{success}</p>}
      <button
        type="submit"
        disabled={loading}
        className="bg-teal-600 hover:bg-teal-700 disabled:opacity-50 text-white text-sm font-medium px-4 py-2 rounded-md transition"
      >
        {loading ? 'Extending...' : 'Extend License'}
      </button>
    </form>
  );
}
