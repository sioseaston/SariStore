import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../db_helper.dart';
import '../../models/transaction.dart';

const _uuid = Uuid();

class BuyerDao {
  Future<Database> get _db async => DBHelper.instance.database;

  Future<Buyer> create({required String name, String? contactNumber}) async {
    final db = await _db;
    final buyer = Buyer(
      id: _uuid.v4(),
      name: name,
      contactNumber: contactNumber,
      totalOutstandingBalance: 0,
      createdAt: DateTime.now(),
    );
    await db.insert('buyers', buyer.toMap());
    return buyer;
  }

  Future<List<Buyer>> search(String query) async {
    final db = await _db;
    final rows = await db.query(
      'buyers',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    return rows.map(Buyer.fromMap).toList();
  }

  Future<Buyer?> getById(String id) async {
    final db = await _db;
    final rows = await db.query('buyers', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Buyer.fromMap(rows.first);
  }

  /// Buyers with an outstanding balance > 0, for the Collectibles screen.
  Future<List<Buyer>> getWithOutstandingBalance() async {
    final db = await _db;
    final rows = await db.query(
      'buyers',
      where: 'total_outstanding_balance > 0',
      orderBy: 'total_outstanding_balance DESC',
    );
    return rows.map(Buyer.fromMap).toList();
  }

  /// Unpaid/partially-paid transactions belonging to a specific buyer,
  /// for the buyer-detail drill-down screen.
  Future<List<SaleTransaction>> getOpenTransactionsForBuyer(String buyerId) async {
    final db = await _db;
    final rows = await db.query(
      'transactions',
      where: "buyer_id = ? AND status = 'pending_credit'",
      whereArgs: [buyerId],
      orderBy: 'created_at DESC',
    );
    return rows.map(SaleTransaction.fromMap).toList();
  }
}
