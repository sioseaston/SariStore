/**
 * One-time script to create the first admin login.
 * Run with: npx tsx scripts/seed-admin.ts you@example.com yourpassword
 */
import { config } from 'dotenv';
import { resolve } from 'path';
import { createClient } from '@supabase/supabase-js';
import bcrypt from 'bcryptjs';

// This script runs standalone via tsx, outside Next.js's dev server, so
// .env.local is NOT loaded automatically the way it is for `next dev`.
// Load it explicitly here.
config({ path: resolve(process.cwd(), '.env.local') });

async function main() {
  const [, , email, password] = process.argv;
  if (!email || !password) {
    console.error('Usage: npx tsx scripts/seed-admin.ts <email> <password>');
    process.exit(1);
  }

  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!supabaseUrl || !supabaseKey) {
    console.error('SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY must be set in the environment');
    process.exit(1);
  }

  const db = createClient(supabaseUrl, supabaseKey);
  const passwordHash = await bcrypt.hash(password, 10);

  const { error } = await db
    .from('admin_users')
    .insert({ email: email.toLowerCase().trim(), password_hash: passwordHash });

  if (error) {
    console.error('Failed to create admin user:', error.message);
    process.exit(1);
  }

  console.log(`Admin user created: ${email}`);
}

main();