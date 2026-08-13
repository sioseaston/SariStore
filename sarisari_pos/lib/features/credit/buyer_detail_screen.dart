import 'package:flutter/material.dart';
import '../../data/local/daos/buyer_dao.dart';
import '../../data/local/daos/transaction_dao.dart';
import '../../data/models/transaction.dart';

class BuyerDetailScreen extends StatefulWidget {
  const BuyerDetailScreen({super.key, required this.buyer});

  final Buyer buyer;

  @override
  State<BuyerDetailScreen> createState() => _BuyerDetailScreenState();
}

class _BuyerDetailScreenState extends State<BuyerDetailScreen> {
  final _buyerDao = BuyerDao();
  final _transactionDao = TransactionDao();

  late Buyer _buyer;
  List<SaleTransaction> _openTransactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _buyer = widget.buyer;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final refreshedBuyer = await _buyerDao.getById(_buyer.id);
    final openTxns = await _buyerDao.getOpenTransactionsForBuyer(_buyer.id);
    if (!mounted) return;
    setState(() {
      if (refreshedBuyer != null) _buyer = refreshedBuyer;
      _openTransactions = openTxns;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_buyer.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.orange.shade50,
                  child: Column(
                    children: [
                      const Text('Total Balance', style: TextStyle(color: Colors.grey)),
                      Text(
                        '₱${_buyer.totalOutstandingBalance.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                      if (_buyer.contactNumber != null) ...[
                        const SizedBox(height: 4),
                        Text(_buyer.contactNumber!, style: const TextStyle(color: Colors.grey)),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Unpaid Sales (${_openTransactions.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                Expanded(
                  child: _openTransactions.isEmpty
                      ? const Center(child: Text('No unpaid transactions for this buyer.'))
                      : ListView.builder(
                          itemCount: _openTransactions.length,
                          itemBuilder: (ctx, i) {
                            final txn = _openTransactions[i];
                            final balance = txn.total - txn.amountTendered;
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text('Sale: ₱${txn.total.toStringAsFixed(2)}'),
                                subtitle: Text(
                                  '${_formatDate(txn.createdAt)}\nPaid ₱${txn.amountTendered.toStringAsFixed(2)} · '
                                  'Balance ₱${balance.toStringAsFixed(2)}',
                                ),
                                isThreeLine: true,
                                trailing: FilledButton(
                                  onPressed: () async {
                                    await Navigator.pushNamed(
                                      context,
                                      '/credit/add-payment',
                                      arguments: {'buyer': _buyer, 'transaction': txn},
                                    );
                                    _load();
                                  },
                                  child: const Text('Pay'),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
