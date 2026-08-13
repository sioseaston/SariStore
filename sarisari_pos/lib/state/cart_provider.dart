import 'package:flutter/foundation.dart';
import '../data/models/product.dart';
import '../data/models/transaction.dart';

/// Holds the current sale-in-progress. Purely in-memory — nothing here
/// touches SQLite. Stock is only ever deducted at checkout confirmation
/// (see SaleRepository.checkout), so an abandoned/cleared cart never
/// needs cleanup.
class CartProvider extends ChangeNotifier {
  final List<CartLine> _lines = [];

  List<CartLine> get lines => List.unmodifiable(_lines);

  bool get isEmpty => _lines.isEmpty;

  double get subtotal => _lines.fold(0, (sum, l) => sum + l.lineTotal);

  int get itemCount => _lines.fold(0, (sum, l) => sum + l.qty.round());

  /// Adds a scanned/selected product to the cart. If it's already in the
  /// cart, increments qty instead of adding a duplicate line.
  /// Returns a warning string if the requested qty exceeds live stock
  /// (caller decides whether to block or just show the warning).
  String? addProduct(Product product, {double qty = 1}) {
    final existingIndex = _lines.indexWhere((l) => l.product.id == product.id);
    final newQty = existingIndex >= 0 ? _lines[existingIndex].qty + qty : qty;

    if (existingIndex >= 0) {
      _lines[existingIndex].qty = newQty;
    } else {
      _lines.add(CartLine(product: product, qty: qty));
    }
    notifyListeners();

    if (newQty > product.stockQty) {
      return 'Only ${product.stockQty} ${product.unit} of ${product.name} in stock';
    }
    return null;
  }

  void updateQty(String productId, double qty) {
    final index = _lines.indexWhere((l) => l.product.id == productId);
    if (index < 0) return;
    if (qty <= 0) {
      _lines.removeAt(index);
    } else {
      _lines[index].qty = qty;
    }
    notifyListeners();
  }

  void removeLine(String productId) {
    _lines.removeWhere((l) => l.product.id == productId);
    notifyListeners();
  }

  /// Returns lines whose requested qty exceeds current stock — used to
  /// gate the "Checkout" button and show inline warnings.
  List<CartLine> get overStockLines =>
      _lines.where((l) => l.qty > l.product.stockQty).toList();

  void clear() {
    _lines.clear();
    notifyListeners();
  }
}
