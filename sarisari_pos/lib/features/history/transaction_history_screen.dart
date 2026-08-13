import 'package:flutter/material.dart';
import '../../data/local/daos/transaction_dao.dart';
import '../../data/models/transaction.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _transactionDao = TransactionDao();
  List<SaleTransaction> _transactions = [];
  bool _loading = true;
  String? _statusFilter; // null = all

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final txns = await _transactionDao.getAll(statusFilter: _statusFilter);
    if (!mounted) return;
    setState(() {
      _transactions = txns;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(null, 'All'),
                  _filterChip('completed', 'Completed'),
                  _filterChip('pending_credit', 'Utang (Unpaid)'),
                  _filterChip('settled', 'Settled'),
                  _filterChip('voided', 'Voided'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? const Center(child: Text('No transactions found.'))
                    : ListView.builder(
                        itemCount: _transactions.length,
                        itemBuilder: (ctx, i) {
                          final txn = _transactions[i];
                          return _TransactionTile(
                            transaction: txn,
                            onTap: () async {
                              await Navigator.pushNamed(context, '/history/detail', arguments: txn);
                              _load(); // refresh in case a void happened
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String? value, String label) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _statusFilter = value);
          _load();
        },
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction, required this.onTap});

  final SaleTransaction transaction;
  final VoidCallback onTap;

  Color _statusColor(TransactionStatus s) {
    switch (s) {
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.voided:
        return Colors.red;
      case TransactionStatus.settled:
        return Colors.blue;
      case TransactionStatus.pendingCredit:
        return Colors.orange;
    }
  }

  String _statusLabel(TransactionStatus s) {
    switch (s) {
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.voided:
        return 'Voided';
      case TransactionStatus.settled:
        return 'Settled';
      case TransactionStatus.pendingCredit:
        return 'Unpaid (Utang)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = transaction.createdAt;
    final timeStr = '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _statusColor(transaction.status).withOpacity(0.15),
        child: Icon(
          transaction.status == TransactionStatus.voided ? Icons.undo : Icons.receipt,
          color: _statusColor(transaction.status),
          size: 20,
        ),
      ),
      title: Text('₱${transaction.total.toStringAsFixed(2)} · ${transaction.paymentType.name.toUpperCase()}'),
      subtitle: Text(timeStr),
      trailing: Chip(
        label: Text(_statusLabel(transaction.status), style: const TextStyle(fontSize: 11)),
        backgroundColor: _statusColor(transaction.status).withOpacity(0.1),
        labelStyle: TextStyle(color: _statusColor(transaction.status)),
        visualDensity: VisualDensity.compact,
      ),
      onTap: onTap,
    );
  }
}
