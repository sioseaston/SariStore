import 'package:flutter/material.dart';
import '../../data/local/daos/product_dao.dart';
import '../../data/models/product.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _productDao = ProductDao();
  final _searchController = TextEditingController();
  List<Product> _products = [];
  bool _loading = true;
  bool _lowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final query = _searchController.text.trim();
    final products = _lowStockOnly
        ? await _productDao.getLowStock()
        : query.isEmpty
            ? await _productDao.getAllActive()
            : await _productDao.search(query);
    if (!mounted) return;
    setState(() {
      _products = products;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: Icon(_lowStockOnly ? Icons.warning : Icons.warning_amber_outlined),
            tooltip: 'Show low stock only',
            onPressed: () {
              setState(() => _lowStockOnly = !_lowStockOnly);
              _load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => _load(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('No products found.'))
                    : ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (ctx, i) {
                          final p = _products[i];
                          return ListTile(
                            title: Text(p.name),
                            subtitle: Text(
                              '₱${p.sellPrice.toStringAsFixed(2)} · ${p.stockQty} ${p.unit} in stock'
                              '${p.barcode != null ? ' · ${p.barcode}' : ''}',
                            ),
                            leading: CircleAvatar(
                              backgroundColor: p.isLowStock ? Colors.red.shade100 : Colors.teal.shade50,
                              child: Icon(
                                p.isLowStock ? Icons.warning : Icons.inventory_2,
                                color: p.isLowStock ? Colors.red : Colors.teal,
                                size: 20,
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Navigator.pushNamed(context, '/inventory/edit', arguments: p);
                              _load();
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'restock',
            onPressed: () async {
              await Navigator.pushNamed(context, '/inventory/restock');
              _load();
            },
            icon: const Icon(Icons.add_box),
            label: const Text('Restock'),
            backgroundColor: Colors.orange,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () async {
              await Navigator.pushNamed(context, '/inventory/add');
              _load();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          ),
        ],
      ),
    );
  }
}
