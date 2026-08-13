import { createClient } from '@supabase/supabase-js';

// Use the service-role key here (server-side only, never exposed to client)
// since these API routes need to bypass row-level security to update
// store status/payment fields directly.
const supabaseUrl = process.env.SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

if (!supabaseUrl || !supabaseServiceKey) {
  throw new Error('SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY env vars are not set');
}

export const db = createClient(supabaseUrl, supabaseServiceKey, {
  auth: { persistSession: false },
});

export interface StoreRow {
  id: string;
  store_name: string;
  license_key: string;
  license_type: 'lifetime' | 'subscription';
  status: 'active' | 'paused' | 'disabled' | 'deleted';
  device_id: string | null;
  activated_at: string | null;
  activation_verified: boolean;
  amount_due: number;
  due_date: string | null;
  last_payment_date: string | null;
  cycle_days: number;
  grace_period_days: number;
}
