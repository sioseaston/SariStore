import crypto from 'crypto';

// Must match the secret compiled into the Flutter app's LicenseService
// (passed at build time via --dart-define=LICENSE_HMAC_SECRET=...).
// Store this in an env var, never commit it.
const HMAC_SECRET = process.env.LICENSE_HMAC_SECRET!;

if (!HMAC_SECRET) {
  throw new Error('LICENSE_HMAC_SECRET env var is not set');
}

export type LicenseType = 'lifetime' | 'subscription';

export interface LicenseTokenPayload {
  store_id: string;
  license_type: LicenseType;
  expires_at: string | null; // ISO string, null for lifetime
  issued_at: string; // ISO string
}

/**
 * Builds the exact string that gets signed. MUST match
 * LicenseToken.signingPayload in the Flutter app field-for-field,
 * including the 'null' literal for missing expiry.
 */
function buildSigningPayload(p: LicenseTokenPayload): string {
  const expires = p.expires_at ?? 'null';
  return `${p.store_id}|${p.license_type}|${expires}|${p.issued_at}`;
}

export function signToken(p: LicenseTokenPayload): string {
  const payload = buildSigningPayload(p);
  return crypto.createHmac('sha256', HMAC_SECRET).update(payload).digest('hex');
}

/**
 * Builds a full signed token object ready to send back to the app.
 */
export function issueToken(params: {
  storeId: string;
  licenseType: LicenseType;
  cycleDays?: number; // required for subscription
}): { token_json: Record<string, unknown> } {
  const issuedAt = new Date();
  let expiresAt: Date | null = null;

  if (params.licenseType === 'subscription') {
    const days = params.cycleDays ?? 30;
    expiresAt = new Date(issuedAt.getTime() + days * 24 * 60 * 60 * 1000);
  }

  const payload: LicenseTokenPayload = {
    store_id: params.storeId,
    license_type: params.licenseType,
    expires_at: expiresAt ? expiresAt.toISOString() : null,
    issued_at: issuedAt.toISOString(),
  };

  const signature = signToken(payload);

  return {
    token_json: {
      store_id: payload.store_id,
      license_type: payload.license_type,
      expires_at: payload.expires_at,
      issued_at: payload.issued_at,
      signature,
    },
  };
}
