import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/license_token.dart';

class LicenseApiException implements Exception {
  final String message;
  final String? code; // e.g. 'unpaid', 'invalid_key', 'device_mismatch', 'disabled'
  LicenseApiException(this.message, {this.code});

  @override
  String toString() => 'LicenseApiException($code): $message';
}

/// Talks to the backend licensing server. All calls here require connectivity;
/// callers should catch network failures and fall back to the locally cached
/// token (see LicenseService) rather than blocking the user.
class LicenseApi {
  LicenseApi({required this.baseUrl});
  final String baseUrl;

  /// First-time activation. Called once for lifetime stores, and once at
  /// initial setup for subscription stores (renewals use [checkStatus]).
  Future<LicenseToken> activate({
    required String licenseKey,
    required String deviceId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/license/activate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'license_key': licenseKey, 'device_id': deviceId}),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode != 200) {
      throw LicenseApiException(
        body['message'] as String? ?? 'Activation failed',
        code: body['code'] as String?,
      );
    }

    return LicenseToken.fromJson(body['token'] as Map<String, dynamic>);
  }

  /// Renewal / periodic check-in for subscription stores. Also used to detect
  /// remote pause/disable for lifetime stores on the rare occasion they reconnect.
  Future<LicenseToken> checkStatus({
    required String storeId,
    required String deviceId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/license/check-status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'store_id': storeId, 'device_id': deviceId}),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode != 200) {
      // 'unpaid' is the expected case when a subscription store hasn't renewed —
      // surface this distinctly so the UI can show amount due instead of a generic error.
      throw LicenseApiException(
        body['message'] as String? ?? 'Status check failed',
        code: body['code'] as String?, // 'unpaid' | 'disabled' | 'paused' | ...
      );
    }

    return LicenseToken.fromJson(body['token'] as Map<String, dynamic>);
  }
}
