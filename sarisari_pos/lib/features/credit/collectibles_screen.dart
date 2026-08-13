import 'package:flutter/material.dart';
import '../../data/local/daos/buyer_dao.dart';
import '../../data/models/transaction.dart';

class CollectiblesScreen extends StatefulWidget {
  const CollectiblesScreen({super.key});

  @override
  State<CollectiblesScreen> createState() => _CollectiblesScreenState();
}

class _CollectiblesScreenState extends State<CollectiblesScreen> {
  final _buyerDao = BuyerDao();
  List<Buyer> _buyers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final buyers = await _buyerDao.getWithOutstandingBalance();
    if (!mounted) return;
    setState(() {
      _buyers = buyers;
      _loading = false;
    });
  }

  double get _totalOutstanding =>
      _buyers.fold(0, (sum, b) => sum + b.totalOutstandingBalance);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collectibles')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.orange.shade50,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Total Outstanding', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        '₱${_totalOutstanding.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                      const SizedBox(height: 2),
                      Text('${_buyers.length} buyer(s) with unpaid balance',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Expanded(
                  child: _buyers.isEmpty
                      ? const Center(child: Text('No outstanding utang. 🎉'))
                      : ListView.builder(
                          itemCount: _buyers.length,
                          itemBuilder: (ctx, i) {
                            final buyer = _buyers[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange.shade100,
                                child: Text(
                                  buyer.name.isNotEmpty ? buyer.name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.orange),
                                ),
                              ),
                              title: Text(buyer.name),
                              subtitle: buyer.contactNumber != null ? Text(buyer.contactNumber!) : null,
                              trailing: Text(
                                '₱${buyer.totalOutstandingBalance.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                              ),
                              onTap: () async {
                                await Navigator.pushNamed(context, '/credit/buyer', arguments: buyer);
                                _load(); // refresh totals after any payment
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
