import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/models/product.dart';

/// Shown right after adding a product with a store-generated code (prefix
/// 'SS-'), so the owner can immediately print/save a sticker for it.
/// Also reachable later from the product detail screen for re-printing.
class QrGenerateScreen extends StatelessWidget {
  const QrGenerateScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final code = product.barcode ?? product.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Product Sticker')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    QrImageView(
                      data: code,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '₱${product.sellPrice.toStringAsFixed(2)} / ${product.unit}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(code, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Print this on a sticker/label and attach it to the item, '
              'or write the code by hand if no printer is available.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('Print'),
                    onPressed: () {
                      // Wire up printer_service.dart (Bluetooth label/thermal printer).
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Printer not connected yet')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.popUntil(context, (r) => r.settings.name == '/inventory'),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
