import 'package:sqflite/sqflite.dart';
import '../db_helper.dart';
import '../../models/product.dart';

class ProductDao {
  Future<Database> get _db async => DBHelper.instance.database;

  Future<void> insert(Product p) async {
    final db = await _db;
    await db.insert('products', p.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<void> update(Product p) async {
    final db = await _db;
    await db.update('products', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<void> softDelete(String id) async {
    final db = await _db;
    await db.update('products', {'is_active': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<Product?> getById(String id) async {
    final db = await _db;
    final rows = await db.query('products', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<Product?> getByBarcode(String barcode) async {
    final db = await _db;
    final rows = await db.query(
      'products',
      where: 'barcode = ? AND is_active = 1',
      whereArgs: [barcode],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<List<Product>> search(String query) async {
    final db = await _db;
    final rows = await db.query(
      'products',
      where: 'is_active = 1 AND name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<List<Product>> getAllActive() async {
    final db = await _db;
    final rows = await db.query('products', where: 'is_active = 1', orderBy: 'name ASC');
    return rows.map(Product.fromMap).toList();
  }

  Future<List<Product>> getLowStock() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT * FROM products
      WHERE is_active = 1 AND stock_qty <= reorder_level
      ORDER BY stock_qty ASC
    ''');
    return rows.map(Product.fromMap).toList();
  }

  /// Adjusts stock by [delta] (positive to add, negative to deduct).
  /// Uses a raw SQL increment so concurrent writes don't clobber each other.
  /// Must be called within the same [txn] as the movement log insert to stay atomic.
  Future<void> adjustStock(DatabaseExecutor txn, String productId, double delta) async {
    await txn.rawUpdate(
      'UPDATE products SET stock_qty = stock_qty + ?, updated_at = ? WHERE id = ?',
      [delta, DateTime.now().toIso8601String(), productId],
    );
  }
}
