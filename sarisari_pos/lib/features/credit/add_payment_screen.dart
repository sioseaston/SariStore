import 'package:flutter/material.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/sale_repository.dart';

class AddPaymentScreen extends StatefulWidget {
  const AddPaymentScreen({super.key, required this.buyer, required this.transaction});

  final Buyer buyer;
  final SaleTransaction transaction;

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _saleRepository = SaleRepository();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;
  String? _error;

  double get _balance => widget.transaction.total - widget.transaction.amountTendered;

  @override
  void initState() {
    super.initState();
    // Default to full remaining balance — cashier can edit down for a partial payment.
    _amountController.text = _balance.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    if (amount > _balance) {
      setState(() => _error = 'Amount cannot exceed the remaining balance of ₱${_balance.toStringAsFixed(2)}');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _saleRepository.addCreditPayment(
        transactionId: widget.transaction.id,
        buyerId: widget.buyer.id,
        amount: amount,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Failed to record payment: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Buyer: ${widget.buyer.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Sale total: ₱${widget.transaction.total.toStringAsFixed(2)}'),
                    Text('Already paid: ₱${widget.transaction.amountTendered.toStringAsFixed(2)}'),
                    Text(
                      'Remaining balance: ₱${_balance.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount Paid Now',
                prefixText: '₱ ',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Confirm Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
