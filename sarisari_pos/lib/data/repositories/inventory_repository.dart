import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../local/db_helper.dart';

const _uuid = Uuid();

/// Handles stock changes that originate from the Inventory tab (restock,
/// manual adjustment, spoilage) — as opposed to sales/voids, which go
/// through SaleRepository. Kept separate so each repository's atomic
/// transaction boundary maps cleanly to one user-facing action.
class InventoryRepository {
  Future<Database> get _db async => DBHelper.instance.database;

  Future<void> restock({
    required String productId,
    required double qty,
    String? notes,
  }) async {
    if (qty <= 0) {
      throw ArgumentError('Restock quantity must be positive');
    }
    final db = await _db;
    final now = DateTime.now();

    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE products SET stock_qty = stock_qty + ?, updated_at = ? WHERE id = ?',
        [qty, now.toIso8601String(), productId],
      );
      await txn.insert('stock_movements', {
        'id': _uuid.v4(),
        'product_id': productId,
        'type': 'restock',
        'qty': qty,
        'reference_id': null,
        'notes': notes,
        'created_at': now.toIso8601String(),
      });
    });
  }

  /// Manual correction (e.g. physical count differs from system count) or
  /// spoilage/loss. [delta] can be positive or negative.
  Future<void> adjustStock({
    required String productId,
    required double delta,
    required String type, // 'adjustment' | 'spoilage'
    String? notes,
  }) async {
    final db = await _db;
    final now = DateTime.now();

    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE products SET stock_qty = stock_qty + ?, updated_at = ? WHERE id = ?',
        [delta, now.toIso8601String(), productId],
      );
      await txn.insert('stock_movements', {
        'id': _uuid.v4(),
        'product_id': productId,
        'type': type,
        'qty': delta,
        'reference_id': null,
        'notes': notes,
        'created_at': now.toIso8601String(),
      });
    });
  }
}
