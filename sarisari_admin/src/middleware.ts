import { NextRequest, NextResponse } from 'next/server';
import { verifySessionToken, SESSION_COOKIE_NAME } from '@/lib/auth';

/// Routes that require a logged-in admin. The public license endpoints
/// (/api/license/*) are deliberately excluded — those are called by the
/// Flutter app itself, not the admin dashboard, and are authenticated
/// differently (license_key / device_id, not an admin session).
const PROTECTED_PREFIXES = ['/dashboard', '/api/stores'];

export async function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;

  const needsAuth = PROTECTED_PREFIXES.some((p) => pathname.startsWith(p));
  if (!needsAuth) return NextResponse.next();

  const token = req.cookies.get(SESSION_COOKIE_NAME)?.value;
  const session = token ? await verifySessionToken(token) : null;

  if (!session) {
    if (pathname.startsWith('/api/')) {
      return NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
    }
    const loginUrl = new URL('/login', req.url);
    loginUrl.searchParams.set('redirect', pathname);
    return NextResponse.redirect(loginUrl);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/dashboard/:path*', '/api/stores/:path*'],
};
