'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

export default function CreateStorePage() {
  const router = useRouter();
  const [storeName, setStoreName] = useState('');
  const [ownerName, setOwnerName] = useState('');
  const [contactNumber, setContactNumber] = useState('');
  const [licenseType, setLicenseType] = useState<'lifetime' | 'subscription'>('subscription');
  const [initialAmountDue, setInitialAmountDue] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [createdKey, setCreatedKey] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);

    const res = await fetch('/api/stores', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        store_name: storeName,
        owner_name: ownerName || undefined,
        contact_number: contactNumber || undefined,
        license_type: licenseType,
        initial_amount_due: initialAmountDue ? Number(initialAmountDue) : 0,
      }),
    });

    setLoading(false);
    const body = await res.json().catch(() => ({}));

    if (!res.ok) {
      setError(body.message ?? 'Failed to create store');
      return;
    }

    setCreatedKey(body.license_key);
  }

  if (createdKey) {
    return (
      <div className="max-w-lg mx-auto px-6 py-12">
        <div className="bg-white border border-gray-200 rounded-lg p-8 text-center">
          <div className="text-4xl mb-3">✅</div>
          <h1 className="text-lg font-semibold mb-2">Store Created</h1>
          <p className="text-sm text-gray-500 mb-4">
            Send this license key to the owner. It won&apos;t be shown again in plaintext.
          </p>
          <div className="bg-gray-100 rounded-md px-4 py-3 font-mono text-lg tracking-wide mb-6">
            {createdKey}
          </div>
          <div className="flex gap-3 justify-center">
            <button
              onClick={() => navigator.clipboard.writeText(createdKey)}
              className="text-sm border border-gray-300 rounded-md px-4 py-2 hover:bg-gray-50"
            >
              Copy Key
            </button>
            <button
              onClick={() => router.push('/dashboard')}
              className="text-sm bg-teal-600 hover:bg-teal-700 text-white rounded-md px-4 py-2"
            >
              Back to Dashboard
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-lg mx-auto px-6 py-8">
      <Link href="/dashboard" className="text-sm text-gray-500 hover:text-gray-800">
        ← Back
      </Link>
      <h1 className="text-2xl font-semibold mt-2 mb-6">Create Store</h1>

      <form onSubmit={handleSubmit} className="space-y-4 bg-white border border-gray-200 rounded-lg p-6">
        <div>
          <label className="block text-sm font-medium mb-1">Store Name *</label>
          <input
            required
            value={storeName}
            onChange={(e) => setStoreName(e.target.value)}
            className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm"
            placeholder="e.g. Aling Nena's Store"
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Owner Name</label>
          <input
            value={ownerName}
            onChange={(e) => setOwnerName(e.target.value)}
            className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm"
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Contact Number</label>
          <input
            value={contactNumber}
            onChange={(e) => setContactNumber(e.target.value)}
            className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm"
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">License Type *</label>
          <div className="flex gap-3">
            {(['subscription', 'lifetime'] as const).map((type) => (
              <button
                type="button"
                key={type}
                onClick={() => setLicenseType(type)}
                className={`flex-1 border rounded-md px-3 py-2 text-sm capitalize transition ${
                  licenseType === type
                    ? 'border-teal-600 bg-teal-50 text-teal-700 font-medium'
                    : 'border-gray-300 text-gray-600'
                }`}
              >
                {type}
              </button>
            ))}
          </div>
          <p className="text-xs text-gray-400 mt-1">
            {licenseType === 'subscription'
              ? 'Auto-locks every 30 days until renewed.'
              : 'One-time payment, activates once, never expires locally.'}
          </p>
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">
            Initial Amount Due {licenseType === 'lifetime' ? '(full payment)' : '(optional)'}
          </label>
          <input
            type="number"
            min="0"
            step="0.01"
            value={initialAmountDue}
            onChange={(e) => setInitialAmountDue(e.target.value)}
            className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm"
            placeholder="₱"
          />
        </div>

        {error && <p className="text-sm text-red-600">{error}</p>}

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-teal-600 hover:bg-teal-700 disabled:opacity-50 text-white text-sm font-medium py-2 rounded-md transition"
        >
          {loading ? 'Creating...' : 'Create Store'}
        </button>
      </form>
    </div>
  );
}
