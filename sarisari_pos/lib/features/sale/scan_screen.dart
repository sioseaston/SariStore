import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../data/local/daos/product_dao.dart';
import '../../data/models/product.dart';
import '../../services/qr_scanner_service.dart';
import '../../state/cart_provider.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _scannerService = QrScannerService();
  final _productDao = ProductDao();
  final _searchController = TextEditingController();

  bool _isProcessing = false; // debounce: avoid double-adds on rapid frames
  List<Product> _searchResults = [];

  @override
  void dispose() {
    _scannerService.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final code = _scannerService.extractCode(capture);
    if (code == null) return;

    setState(() => _isProcessing = true);
    try {
      final product = await _productDao.getByBarcode(code);
      if (!mounted) return;

      if (product == null) {
        _showNotFoundDialog(code);
        return;
      }
      _addToCart(product);
    } finally {
      // Small delay so the same code isn't re-scanned instantly if the
      // camera is still pointed at it.
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _addToCart(Product product) {
    final cart = context.read<CartProvider>();
    final warning = cart.addProduct(product);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(warning ?? 'Added ${product.name}'),
        backgroundColor: warning != null ? Colors.orange : Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showNotFoundDialog(String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Product not found'),
        content: Text('No product matches this code:\n$code'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/inventory/add', arguments: code);
            },
            child: const Text('Add New Product'),
          ),
        ],
      ),
    );
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final results = await _productDao.search(query.trim());
    if (mounted) setState(() => _searchResults = results);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Product'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _scannerService.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerService.controller,
                  onDetect: _onDetect,
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Or search product by name...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            flex: 2,
            child: _searchResults.isEmpty
                ? const SizedBox.shrink()
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (ctx, i) {
                      final p = _searchResults[i];
                      return ListTile(
                        title: Text(p.name),
                        subtitle: Text('₱${p.sellPrice.toStringAsFixed(2)} · ${p.stockQty} ${p.unit} left'),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () => _addToCart(p),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.icon(
                icon: const Icon(Icons.shopping_cart),
                label: Text('View Cart (${cart.itemCount} items · ₱${cart.subtotal.toStringAsFixed(2)})'),
                onPressed: cart.isEmpty ? null : () => Navigator.pushNamed(context, '/sale/cart'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
