enum LicenseType { lifetime, subscription }

enum LicenseState {
  active, // valid, unrestricted
  warning, // subscription nearing expiry / paused by admin
  locked, // expired / disabled — checkout & inventory edits blocked
  noLicense, // never activated
}

class LicenseToken {
  final String storeId;
  final LicenseType licenseType;
  final DateTime? expiresAt; // null for lifetime
  final DateTime issuedAt;
  final String signature; // HMAC/JWT signature from server, verified locally
  final DateTime? lastCheckIn;

  LicenseToken({
    required this.storeId,
    required this.licenseType,
    this.expiresAt,
    required this.issuedAt,
    required this.signature,
    this.lastCheckIn,
  });

  /// The exact string the server signed. Must match server-side signing logic
  /// EXACTLY (field order + format) or signature verification will fail.
  String get signingPayload =>
      '$storeId|${licenseType.name}|${expiresAt?.toIso8601String() ?? 'null'}|${issuedAt.toIso8601String()}';

  bool get isLifetime => licenseType == LicenseType.lifetime;

  bool isExpired(DateTime now) {
    if (isLifetime) return false;
    if (expiresAt == null) return true; // subscription with no expiry = invalid
    return now.isAfter(expiresAt!);
  }

  Map<String, dynamic> toMap() => {
        'store_id': storeId,
        'license_type': licenseType.name,
        'expires_at': expiresAt?.toIso8601String(),
        'issued_at': issuedAt.toIso8601String(),
        'signature': signature,
        'last_check_in': lastCheckIn?.toIso8601String(),
      };

  factory LicenseToken.fromMap(Map<String, dynamic> map) => LicenseToken(
        storeId: map['store_id'] as String,
        licenseType: (map['license_type'] as String) == 'lifetime'
            ? LicenseType.lifetime
            : LicenseType.subscription,
        expiresAt: map['expires_at'] != null ? DateTime.parse(map['expires_at'] as String) : null,
        issuedAt: DateTime.parse(map['issued_at'] as String),
        signature: map['signature'] as String,
        lastCheckIn:
            map['last_check_in'] != null ? DateTime.parse(map['last_check_in'] as String) : null,
      );

  factory LicenseToken.fromJson(Map<String, dynamic> json) => LicenseToken(
        storeId: json['store_id'] as String,
        licenseType: (json['license_type'] as String) == 'lifetime'
            ? LicenseType.lifetime
            : LicenseType.subscription,
        expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
        issuedAt: DateTime.parse(json['issued_at'] as String),
        signature: json['signature'] as String,
        lastCheckIn: DateTime.now(),
      );
}
