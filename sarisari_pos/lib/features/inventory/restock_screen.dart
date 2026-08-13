import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../data/local/daos/product_dao.dart';
import '../../data/models/product.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../services/qr_scanner_service.dart';

class RestockScreen extends StatefulWidget {
  const RestockScreen({super.key});

  @override
  State<RestockScreen> createState() => _RestockScreenState();
}

class _RestockScreenState extends State<RestockScreen> {
  final _scannerService = QrScannerService();
  final _productDao = ProductDao();
  final _inventoryRepository = InventoryRepository();
  final _searchController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  Product? _selectedProduct;
  List<Product> _searchResults = [];
  bool _scanning = true;
  bool _saving = false;

  @override
  void dispose() {
    _scannerService.dispose();
    _searchController.dispose();
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final code = _scannerService.extractCode(capture);
    if (code == null) return;
    final product = await _productDao.getByBarcode(code);
    if (!mounted) return;
    if (product != null) {
      setState(() {
        _selectedProduct = product;
        _scanning = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No product matches this code')),
      );
    }
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final results = await _productDao.search(query.trim());
    if (mounted) setState(() => _searchResults = results);
  }

  Future<void> _submit() async {
    if (_selectedProduct == null) return;
    final qty = double.tryParse(_qtyController.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _inventoryRepository.restock(
        productId: _selectedProduct!.id,
        qty: qty,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restock')),
      body: _selectedProduct == null ? _buildPicker() : _buildQtyForm(),
    );
  }

  Widget _buildPicker() {
    return Column(
      children: [
        if (_scanning)
          Expanded(
            flex: 3,
            child: MobileScanner(controller: _scannerService.controller, onDetect: _onDetect),
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
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (ctx, i) {
              final p = _searchResults[i];
              return ListTile(
                title: Text(p.name),
                subtitle: Text('${p.stockQty} ${p.unit} currently in stock'),
                onTap: () => setState(() => _selectedProduct = p),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQtyForm() {
    final p = _selectedProduct!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: ListTile(
              title: Text(p.name),
              subtitle: Text('Current stock: ${p.stockQty} ${p.unit}'),
              trailing: TextButton(
                onPressed: () => setState(() {
                  _selectedProduct = null;
                  _scanning = true;
                }),
                child: const Text('Change'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _qtyController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Quantity to add (${p.unit})',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'e.g. supplier name, invoice no.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Confirm Restock'),
          ),
        ],
      ),
    );
  }
}
