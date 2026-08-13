/**
 * One-time script to create the first admin login.
 * Run with: npx tsx scripts/seed-admin.ts you@example.com yourpassword
 *
 * (Add "tsx" as a devDependency, or run via `node -r ts-node/register` —
 * any TS runner works since this has no framework dependencies beyond
 * @supabase/supabase-js and bcryptjs, both already in package.json.)
 */
import { createClient } from '@supabase/supabase-js';
import bcrypt from 'bcryptjs';

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
