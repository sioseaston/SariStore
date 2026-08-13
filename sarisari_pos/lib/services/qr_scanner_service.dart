import 'package:mobile_scanner/mobile_scanner.dart';

/// Thin wrapper around mobile_scanner so the rest of the app doesn't
/// depend directly on the scanning package (easier to swap later, e.g.
/// if a specific phone model has camera issues with mobile_scanner).
class QrScannerService {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  /// Extracts the first usable code value from a capture event.
  /// Returns null if no readable code was found in the frame.
  String? extractCode(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  Future<void> toggleTorch() => controller.toggleTorch();

  Future<void> dispose() => controller.dispose();
}
