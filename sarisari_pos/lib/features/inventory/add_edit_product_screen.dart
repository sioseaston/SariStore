import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/daos/product_dao.dart';
import '../../data/models/product.dart';

const _uuid = Uuid();
const _units = ['piece', 'sachet', 'pack', 'kg', 'g', 'l', 'ml'];

class AddEditProductScreen extends StatefulWidget {
  const AddEditProductScreen({super.key, this.existingProduct, this.prefillBarcode});

  /// Pass an existing product to edit it. Null means "create new".
  final Product? existingProduct;

  /// Pass a scanned barcode that didn't match any product, so the field
  /// is pre-filled (from ScanScreen's "not found" dialog).
  final String? prefillBarcode;

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productDao = ProductDao();

  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _costController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _reorderController;
  late String _unit;
  bool _saving = false;

  bool get _isEditing => widget.existingProduct != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProduct;
    _nameController = TextEditingController(text: p?.name ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? widget.prefillBarcode ?? '');
    _costController = TextEditingController(text: p != null ? p.costPrice.toString() : '');
    _priceController = TextEditingController(text: p != null ? p.sellPrice.toString() : '');
    _stockController = TextEditingController(text: p != null ? p.stockQty.toString() : '0');
    _reorderController = TextEditingController(text: p != null ? p.reorderLevel.toString() : '5');
    _unit = p?.unit ?? 'piece';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _costController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _reorderController.dispose();
    super.dispose();
  }

  /// For unbranded/repacked items with no printed barcode — generates a
  /// store-local code the app can print as a sticker via qr_generate_screen.
  void _generateStoreCode() {
    final code = 'SS-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    setState(() => _barcodeController.text = code);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final now = DateTime.now();
    final product = Product(
      id: widget.existingProduct?.id ?? _uuid.v4(),
      barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
      name: _nameController.text.trim(),
      unit: _unit,
      costPrice: double.tryParse(_costController.text) ?? 0,
      sellPrice: double.parse(_priceController.text),
      stockQty: double.tryParse(_stockController.text) ?? 0,
      reorderLevel: double.tryParse(_reorderController.text) ?? 0,
      createdAt: widget.existingProduct?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      if (_isEditing) {
        await _productDao.update(product);
      } else {
        await _productDao.insert(product);
      }
      if (!mounted) return;

      if (!_isEditing && product.barcode != null && product.barcode!.startsWith('SS-')) {
        // Offer to print a sticker for store-generated codes right away.
        Navigator.pushReplacementNamed(context, '/inventory/qr-generate', arguments: product);
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove product?'),
        content: Text('${widget.existingProduct!.name} will be hidden from inventory and sales. '
            'Past transaction history is kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _productDao.softDelete(widget.existingProduct!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
        actions: [
          if (_isEditing)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _confirmDelete),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Barcode / QR Code (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _generateStoreCode,
                  child: const Text('Generate'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _unit,
              decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
              items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
              onChanged: (v) => setState(() => _unit = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _costController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Cost Price', prefixText: '₱ ', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Sell Price', prefixText: '₱ ', border: OutlineInputBorder()),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Enter a valid price';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _isEditing ? 'Current Stock' : 'Initial Stock',
                      border: const OutlineInputBorder(),
                    ),
                    enabled: !_isEditing, // edits to stock go through restock/adjustment, not here
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _reorderController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Reorder Level', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            if (_isEditing) ...[
              const SizedBox(height: 4),
              const Text(
                'To change stock quantity, use Restock or a manual adjustment instead — '
                'this keeps the stock movement history accurate.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? 'Save Changes' : 'Add Product'),
            ),
          ],
        ),
      ),
    );
  }
}
