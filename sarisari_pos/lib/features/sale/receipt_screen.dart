import 'package:flutter/material.dart';
import '../../data/models/transaction.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key, required this.transaction});

  final SaleTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final dt = transaction.createdAt;
    final dateStr = '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 56),
                    const SizedBox(height: 8),
                    const Text('Payment Successful',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Divider(),
                    _row('Receipt No.', transaction.id.substring(0, 8).toUpperCase()),
                    _row('Date', dateStr),
                    _row('Payment Type', transaction.paymentType.name.toUpperCase()),
                    const Divider(),
                    _row('Subtotal', '₱${transaction.subtotal.toStringAsFixed(2)}'),
                    _row('Total', '₱${transaction.total.toStringAsFixed(2)}', bold: true),
                    if (transaction.paymentType == PaymentType.cash) ...[
                      _row('Tendered', '₱${transaction.amountTendered.toStringAsFixed(2)}'),
                      _row('Change', '₱${transaction.changeAmount.toStringAsFixed(2)}'),
                    ] else ...[
                      _row('Paid Now', '₱${transaction.amountTendered.toStringAsFixed(2)}'),
                      _row(
                        'Balance (Utang)',
                        '₱${(transaction.total - transaction.amountTendered).toStringAsFixed(2)}',
                        color: Colors.orange,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('Print'),
                    onPressed: () {
                      // Wire up printer_service.dart here (Bluetooth thermal printer).
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Printer not connected yet')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    onPressed: () {
                      // Wire up share_plus here to send receipt text/image.
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('New Sale'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
