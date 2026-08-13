import 'package:flutter/material.dart';
import '../../data/local/daos/transaction_dao.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/sale_repository.dart';

const _voidReasons = [
  'Wrong item scanned',
  'Buyer changed mind',
  'Returned defective item',
  'Price error',
  'Other',
];

class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({super.key, required this.transaction});

  final SaleTransaction transaction;

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final _transactionDao = TransactionDao();
  final _saleRepository = SaleRepository();

  late SaleTransaction _transaction;
  List<TransactionItemDetail> _items = [];
  String? _buyerName;
  bool _loading = true;
  bool _voiding = false;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _transactionDao.getItemsForTransaction(_transaction.id);
    final buyerName = await _transactionDao.getBuyerName(_transaction.buyerId);
    final refreshed = await _transactionDao.getById(_transaction.id);
    if (!mounted) return;
    setState(() {
      _items = items;
      _buyerName = buyerName;
      if (refreshed != null) _transaction = refreshed;
      _loading = false;
    });
  }

  Future<void> _startVoidFlow() async {
    String? selectedReason = _voidReasons.first;
    final customReasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Void this transaction?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This restores stock for all items and marks the sale as voided. '
                'The original record is kept for your records — it cannot be undone.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedReason,
                decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder()),
                items: _voidReasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setDialogState(() => selectedReason = v),
              ),
              if (selectedReason == 'Other') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: customReasonController,
                  decoration: const InputDecoration(
                    labelText: 'Describe the reason',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Void Transaction'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final reason = selectedReason == 'Other' && customReasonController.text.trim().isNotEmpty
        ? customReasonController.text.trim()
        : (selectedReason ?? 'Unspecified');

    setState(() => _voiding = true);
    try {
      await _saleRepository.voidTransaction(transactionId: _transaction.id, reason: reason);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction voided. Stock has been restored.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to void: $e')),
      );
    } finally {
      if (mounted) setState(() => _voiding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canVoid = _transaction.status == TransactionStatus.completed ||
        _transaction.status == TransactionStatus.pendingCredit;

    return Scaffold(
      appBar: AppBar(title: Text('Receipt #${_transaction.id.substring(0, 8).toUpperCase()}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _transaction.status.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _transaction.status == TransactionStatus.voided
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                            Text(_formatDate(_transaction.createdAt)),
                          ],
                        ),
                        if (_transaction.status == TransactionStatus.voided &&
                            _transaction.voidReason != null) ...[
                          const SizedBox(height: 8),
                          Text('Void reason: ${_transaction.voidReason}',
                              style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ],
                        if (_buyerName != null) ...[
                          const SizedBox(height: 8),
                          Text('Buyer: $_buyerName'),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._items.map((d) => ListTile(
                      dense: true,
                      title: Text(d.productName),
                      subtitle: Text('₱${d.item.unitPrice.toStringAsFixed(2)} × ${d.item.qty} ${d.productUnit}'),
                      trailing: Text('₱${d.item.lineTotal.toStringAsFixed(2)}'),
                    )),
                const Divider(),
                _summaryRow('Subtotal', _transaction.subtotal),
                _summaryRow('Total', _transaction.total, bold: true),
                if (_transaction.paymentType == PaymentType.cash) ...[
                  _summaryRow('Tendered', _transaction.amountTendered),
                  _summaryRow('Change', _transaction.changeAmount),
                ] else ...[
                  _summaryRow('Paid', _transaction.amountTendered),
                  _summaryRow('Balance', _transaction.total - _transaction.amountTendered,
                      color: Colors.orange),
                ],
                const SizedBox(height: 24),
                if (canVoid)
                  FilledButton.icon(
                    icon: const Icon(Icons.undo),
                    label: _voiding ? const Text('Voiding...') : const Text('Void Transaction'),
                    onPressed: _voiding ? null : _startVoidFlow,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '₱${value.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
