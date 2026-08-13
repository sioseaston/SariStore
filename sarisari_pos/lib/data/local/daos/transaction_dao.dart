import 'package:sqflite/sqflite.dart';
import '../db_helper.dart';
import '../../models/transaction.dart';

/// A transaction_item enriched with the product name/unit at time of query,
/// since transaction_items only stores product_id + the price at sale time.
class TransactionItemDetail {
  final TransactionItem item;
  final String productName;
  final String productUnit;

  TransactionItemDetail({
    required this.item,
    required this.productName,
    required this.productUnit,
  });
}

class TransactionDao {
  Future<Database> get _db async => DBHelper.instance.database;

  /// Most recent transactions first. [statusFilter] narrows to one status
  /// (e.g. 'completed', 'voided') — null returns everything.
  Future<List<SaleTransaction>> getAll({String? statusFilter, int limit = 200}) async {
    final db = await _db;
    final rows = await db.query(
      'transactions',
      where: statusFilter != null ? 'status = ?' : null,
      whereArgs: statusFilter != null ? [statusFilter] : null,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(SaleTransaction.fromMap).toList();
  }

  Future<SaleTransaction?> getById(String id) async {
    final db = await _db;
    final rows = await db.query('transactions', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return SaleTransaction.fromMap(rows.first);
  }

  /// Line items for a transaction, joined with product name/unit for display.
  /// Uses a LEFT JOIN so history still renders correctly even if a product
  /// was later soft-deleted from inventory.
  Future<List<TransactionItemDetail>> getItemsForTransaction(String transactionId) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT ti.*, p.name as product_name, p.unit as product_unit
      FROM transaction_items ti
      LEFT JOIN products p ON p.id = ti.product_id
      WHERE ti.transaction_id = ?
    ''', [transactionId]);

    return rows
        .map((row) => TransactionItemDetail(
              item: TransactionItem.fromMap(row),
              productName: (row['product_name'] as String?) ?? 'Deleted product',
              productUnit: (row['product_unit'] as String?) ?? '',
            ))
        .toList();
  }

  /// Buyer name for display on credit transactions (null if cash sale).
  Future<String?> getBuyerName(String? buyerId) async {
    if (buyerId == null) return null;
    final db = await _db;
    final rows = await db.query('buyers', columns: ['name'], where: 'id = ?', whereArgs: [buyerId], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['name'] as String;
  }
}
