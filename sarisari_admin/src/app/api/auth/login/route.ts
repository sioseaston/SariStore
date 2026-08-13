import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';
import {
  createSessionToken,
  verifyPassword,
  SESSION_COOKIE_NAME,
  SESSION_DURATION_HOURS,
} from '@/lib/auth';

interface AdminUserRow {
  id: string;
  email: string;
  password_hash: string;
}

export async function POST(req: NextRequest) {
  const body = await req.json().catch(() => null);
  const email = body?.email as string | undefined;
  const password = body?.password as string | undefined;

  if (!email || !password) {
    return NextResponse.json(
      { message: 'Email and password are required' },
      { status: 400 },
    );
  }

  const { data: admin, error } = await db
    .from('admin_users')
    .select('*')
    .eq('email', email.toLowerCase().trim())
    .single<AdminUserRow>();

  // Same generic message whether the email doesn't exist or the password is
  // wrong, so the response doesn't leak which admin emails are registered.
  if (error || !admin || !(await verifyPassword(password, admin.password_hash))) {
    return NextResponse.json({ message: 'Invalid email or password' }, { status: 401 });
  }

  const token = await createSessionToken({ adminId: admin.id, email: admin.email });

  const res = NextResponse.json({ message: 'Logged in' }, { status: 200 });
  res.cookies.set(SESSION_COOKIE_NAME, token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: SESSION_DURATION_HOURS * 60 * 60,
    path: '/',
  });
  return res;
}
