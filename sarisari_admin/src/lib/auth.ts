import bcrypt from 'bcryptjs';
import { SignJWT, jwtVerify } from 'jose';

const SESSION_SECRET = process.env.ADMIN_SESSION_SECRET!;
const SESSION_COOKIE_NAME = 'sarisari_admin_session';
const SESSION_DURATION_HOURS = 12;

if (!SESSION_SECRET) {
  throw new Error('ADMIN_SESSION_SECRET env var is not set');
}

function secretKey() {
  return new TextEncoder().encode(SESSION_SECRET);
}

export async function hashPassword(plain: string): Promise<string> {
  return bcrypt.hash(plain, 10);
}

export async function verifyPassword(plain: string, hash: string): Promise<boolean> {
  return bcrypt.compare(plain, hash);
}

export interface SessionPayload {
  adminId: string;
  email: string;
}

export async function createSessionToken(payload: SessionPayload): Promise<string> {
  return new SignJWT({ ...payload })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime(`${SESSION_DURATION_HOURS}h`)
    .sign(secretKey());
}

export async function verifySessionToken(token: string): Promise<SessionPayload | null> {
  try {
    const { payload } = await jwtVerify(token, secretKey());
    return { adminId: payload.adminId as string, email: payload.email as string };
  } catch {
    return null;
  }
}

export { SESSION_COOKIE_NAME, SESSION_DURATION_HOURS };
