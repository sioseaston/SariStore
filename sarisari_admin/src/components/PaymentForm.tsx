'use client';

import { useState } from 'react';

export default function PaymentForm({
  storeId,
  onRecorded,
}: {
  storeId: string;
  onRecorded: () => void;
}) {
  const [amount, setAmount] = useState('');
  const [method, setMethod] = useState('cash');
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);

    const res = await fetch(`/api/stores/${storeId}/mark-paid`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ amount: Number(amount), method, notes: notes || undefined }),
    });

    setLoading(false);

    if (!res.ok) {
      const body = await res.json().catch(() => ({}));
      setError(body.message ?? 'Failed to record payment');
      return;
    }

    setAmount('');
    setNotes('');
    onRecorded();
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-3">
      <div className="flex gap-3">
        <input
          type="number"
          required
          min="0.01"
          step="0.01"
          placeholder="Amount (₱)"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          className="flex-1 border border-gray-300 rounded-md px-3 py-2 text-sm"
        />
        <select
          value={method}
          onChange={(e) => setMethod(e.target.value)}
          className="border border-gray-300 rounded-md px-3 py-2 text-sm"
        >
          <option value="cash">Cash</option>
          <option value="gcash">GCash</option>
          <option value="bank">Bank Transfer</option>
        </select>
      </div>
      <input
        placeholder="Notes (optional)"
        value={notes}
        onChange={(e) => setNotes(e.target.value)}
        className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm"
      />
      {error && <p className="text-sm text-red-600">{error}</p>}
      <button
        type="submit"
        disabled={loading}
        className="bg-teal-600 hover:bg-teal-700 disabled:opacity-50 text-white text-sm font-medium px-4 py-2 rounded-md transition"
      >
        {loading ? 'Recording...' : 'Record Payment'}
      </button>
    </form>
  );
}
