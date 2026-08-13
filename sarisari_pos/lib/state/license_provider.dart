import 'package:flutter/foundation.dart';
import '../data/models/license_token.dart';
import '../data/remote/license_api.dart';
import '../services/device_id_service.dart';
import '../services/license_service.dart';

class LicenseProvider extends ChangeNotifier {
  LicenseProvider({required this.licenseApi})
      : _service = LicenseService(),
        _deviceIdService = DeviceIdService();

  final LicenseApi licenseApi;
  final LicenseService _service;
  final DeviceIdService _deviceIdService;

  LicenseState _state = LicenseState.noLicense;
  LicenseState get state => _state;

  LicenseToken? _token;
  LicenseToken? get token => _token;

  String? _lastError;
  String? get lastError => _lastError;

  double? _amountDue; // populated when server returns 'unpaid'
  double? get amountDue => _amountDue;

  bool _isChecking = false;
  bool get isChecking => _isChecking;

  /// Call on app startup. Purely local — reads the cached token and
  /// evaluates its state, no network required.
  Future<void> loadCachedState() async {
    _token = await _service.getCachedToken();
    _state = await _service.evaluateState();
    notifyListeners();
  }

  /// First-time activation. Requires connectivity.
  Future<bool> activate({required String licenseKey}) async {
    _isChecking = true;
    _lastError = null;
    notifyListeners();

    try {
      final deviceId = await _deviceIdService.getOrCreate();
      final token = await licenseApi.activate(licenseKey: licenseKey, deviceId: deviceId);
      await _service.saveToken(token);
      await _service.updateLastCheckIn(DateTime.now());
      _token = token;
      _state = await _service.evaluateState();
      return true;
    } on LicenseApiException catch (e) {
      _lastError = e.message;
      return false;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Renewal / remote status check. Requires connectivity. Called from the
  /// "Connect to Internet" button on the locked/warning screen, or
  /// automatically in the background when connectivity is detected.
  Future<bool> checkStatus() async {
    final currentToken = _token ?? await _service.getCachedToken();
    if (currentToken == null) {
      _lastError = 'No license found on this device. Please activate first.';
      notifyListeners();
      return false;
    }

    _isChecking = true;
    _lastError = null;
    _amountDue = null;
    notifyListeners();

    try {
      final deviceId = await _deviceIdService.getOrCreate();
      final token = await licenseApi.checkStatus(
        storeId: currentToken.storeId,
        deviceId: deviceId,
      );
      await _service.saveToken(token);
      await _service.updateLastCheckIn(DateTime.now());
      _token = token;
      _state = await _service.evaluateState();
      return true;
    } on LicenseApiException catch (e) {
      _lastError = e.message;
      if (e.code == 'unpaid') {
        _state = LicenseState.locked;
      } else if (e.code == 'disabled') {
        _state = LicenseState.locked;
      }
      return false;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  bool get canTransact => _state == LicenseState.active || _state == LicenseState.warning;
}
