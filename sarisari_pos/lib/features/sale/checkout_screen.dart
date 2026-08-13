import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/local/daos/buyer_dao.dart';
import '../../data/local/daos/settings_dao.dart';
import '../../data/models/transaction.dart'; // Buyer, PaymentType, CartLine live here
import '../../data/repositories/sale_repository.dart';
import '../../state/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _saleRepository = SaleRepository();
  final _buyerDao = BuyerDao();
  final _settingsDao = SettingsDao();
  final _tenderedController = TextEditingController();
  final _buyerNameController = TextEditingController();

  PaymentType _paymentType = PaymentType.cash;
  Buyer? _selectedBuyer;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _tenderedController.dispose();
    _buyerNameController.dispose();
    super.dispose();
  }

  double get _tendered => double.tryParse(_tenderedController.text) ?? 0;

  double _change(double total) =>
      _paymentType == PaymentType.cash ? (_tendered - total).clamp(0, double.infinity) : 0;

  bool _canSubmit(double total) {
    if (_isSubmitting) return false;
    if (_paymentType == PaymentType.cash) return _tendered >= total;
    if (_paymentType == PaymentType.credit || _paymentType == PaymentType.partial) {
      return _selectedBuyer != null && _tendered <= total;
    }
    return false;
  }

  Future<void> _pickOrCreateBuyer() async {
    final query = _buyerNameController.text.trim();
    if (query.isEmpty) return;

    final matches = await _buyerDao.search(query);
    if (!mounted) return;

    if (matches.isEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('New buyer?'),
          content: Text('No existing buyer named "$query". Add as a new buyer for credit tracking?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
          ],
        ),
      );
      if (confirmed == true) {
        final buyer = await _buyerDao.create(name: query);
        setState(() => _selectedBuyer = buyer);
      }
      return;
    }

    if (matches.length == 1) {
      setState(() => _selectedBuyer = matches.first);
      return;
    }

    final chosen = await showDialog<Buyer>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select buyer'),
        children: matches
            .map((b) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, b),
                  child: Text('${b.name}${b.contactNumber != null ? ' · ${b.contactNumber}' : ''}'),
                ))
            .toList(),
      ),
    );
    if (chosen != null) setState(() => _selectedBuyer = chosen);
  }

  Future<void> _confirmPayment(double total) async {
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final cart = context.read<CartProvider>();

    try {
      final allowNegativeStock = await _settingsDao.getBool('allow_negative_stock');
      final transaction = await _saleRepository.checkout(
        cartLines: cart.lines,
        paymentType: _paymentType,
        amountTendered: _paymentType == PaymentType.cash ? _tendered : _tendered,
        buyerId: _selectedBuyer?.id,
        allowNegativeStock: allowNegativeStock,
      );

      cart.clear();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/sale/receipt', arguments: transaction);
    } on InsufficientStockException catch (e) {
      setState(() => _errorText = e.toString());
    } catch (e) {
      setState(() => _errorText = 'Checkout failed: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final total = cart.subtotal;
    final change = _change(total);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Due', style: TextStyle(fontSize: 16)),
                    Text(
                      '₱${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Payment Type', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<PaymentType>(
              segments: const [
                ButtonSegment(value: PaymentType.cash, label: Text('Cash'), icon: Icon(Icons.payments)),
                ButtonSegment(value: PaymentType.credit, label: Text('Utang'), icon: Icon(Icons.book)),
                ButtonSegment(value: PaymentType.partial, label: Text('Partial'), icon: Icon(Icons.percent)),
              ],
              selected: {_paymentType},
              onSelectionChanged: (s) => setState(() => _paymentType = s.first),
            ),
            const SizedBox(height: 16),

            if (_paymentType == PaymentType.credit || _paymentType == PaymentType.partial) ...[
              const Text('Buyer', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _buyerNameController,
                      decoration: const InputDecoration(
                        hintText: 'Search or enter buyer name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _pickOrCreateBuyer, child: const Text('Select')),
                ],
              ),
              if (_selectedBuyer != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Chip(
                    label: Text('Buyer: ${_selectedBuyer!.name}'),
                    onDeleted: () => setState(() => _selectedBuyer = null),
                  ),
                ),
              const SizedBox(height: 16),
            ],

            Text(
              _paymentType == PaymentType.cash
                  ? 'Amount Tendered'
                  : 'Down Payment (optional, can be ₱0)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tenderedController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixText: '₱ ',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),

            if (_paymentType == PaymentType.cash) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Change'),
                  Text(
                    '₱${change.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ] else if (_tendered < total) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Balance to collect later'),
                  Text(
                    '₱${(total - _tendered).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ],
              ),
            ],

            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(_errorText!, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 24),
            FilledButton(
              onPressed: _canSubmit(total) ? () => _confirmPayment(total) : null,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Confirm Payment', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
