import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import '../data/local/db_helper.dart';
import '../data/models/license_token.dart';

/// Handles all local (offline-capable) license logic:
/// - verifying the cached signed token hasn't been tampered with
/// - determining lock state (active / warning / locked / no license)
/// - persisting a newly issued token after a successful server check-in
///
/// IMPORTANT: this class never makes network calls itself — that's the job of
/// LicenseApi (data/remote/license_api.dart). This service only reasons about
/// whatever token is currently cached locally.
class LicenseService {
  // In production this must NOT be a plain string baked into the app —
  // use a proper asymmetric signature (server signs with private key, app
  // verifies with public key) or at minimum obfuscate/store this secret
  // outside of source control. HMAC shared-secret shown here for simplicity.
  static const String _hmacSecret = String.fromEnvironment(
    'LICENSE_HMAC_SECRET',
    defaultValue: 'REPLACE_WITH_REAL_SECRET_AT_BUILD_TIME',
  );

  static const int subscriptionWarningDays = 3; // show banner this many days before expiry

  Future<Database> get _db async => DBHelper.instance.database;

  /// Verifies the HMAC signature on a token against the locally-derived hash
  /// of its payload. Returns false if the token was hand-edited.
  bool verifySignature(LicenseToken token) {
    final expectedSig = _sign(token.signingPayload);
    return expectedSig == token.signature;
  }

  String _sign(String payload) {
    final key = utf8.encode(_hmacSecret);
    final bytes = utf8.encode(payload);
    final hmac = Hmac(sha256, key);
    return hmac.convert(bytes).toString();
  }

  Future<LicenseToken?> getCachedToken() async {
    final db = await _db;
    final rows = await db.query('license', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;
    return LicenseToken.fromMap(rows.first);
  }

  Future<void> saveToken(LicenseToken token) async {
    final db = await _db;
    final map = token.toMap();
    map['id'] = 1;
    await db.insert('license', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateLastCheckIn(DateTime time) async {
    final db = await _db;
    await db.update('license', {'last_check_in': time.toIso8601String()}, where: 'id = 1');
  }

  /// The core gate: call this on every app launch (and after any resume from
  /// background) to decide what the UI should show.
  Future<LicenseState> evaluateState({DateTime? now}) async {
    final token = await getCachedToken();
    if (token == null) return LicenseState.noLicense;

    if (!verifySignature(token)) {
      // Tampered or corrupted token — treat as no valid license at all.
      return LicenseState.locked;
    }

    final currentTime = now ?? DateTime.now();

    if (token.isLifetime) {
      // Lifetime tokens never expire locally. Admin-side disable only takes
      // effect on this device if/when it reconnects and a fresh check-in
      // happens (see LicenseApi.checkStatus) — by design, per the lifetime model.
      return LicenseState.active;
    }

    // Subscription: compare cached expiry against device clock.
    if (token.isExpired(currentTime)) {
      return LicenseState.locked;
    }

    final daysUntilExpiry = token.expiresAt!.difference(currentTime).inDays;
    if (daysUntilExpiry <= subscriptionWarningDays) {
      return LicenseState.warning;
    }

    return LicenseState.active;
  }

  /// Basic tamper signal: if the device clock appears to have jumped
  /// backwards significantly since the last known check-in, flag it.
  /// Doesn't block usage on its own — surface as a soft warning if desired.
  Future<bool> looksLikeClockRollback({DateTime? now}) async {
    final token = await getCachedToken();
    if (token?.lastCheckIn == null) return false;
    final currentTime = now ?? DateTime.now();
    return currentTime.isBefore(token!.lastCheckIn!.subtract(const Duration(days: 1)));
  }
}
