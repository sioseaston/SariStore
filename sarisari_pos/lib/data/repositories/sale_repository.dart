import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../local/db_helper.dart';
import '../models/product.dart';
import '../models/transaction.dart';

const _uuid = Uuid();

/// Thrown when checkout can't proceed because cart stock no longer matches
/// live inventory (e.g. another sale happened in between, or item was deactivated).
class InsufficientStockException implements Exception {
  final String productName;
  final double available;
  final double requested;
  InsufficientStockException(this.productName, this.available, this.requested);

  @override
  String toString() =>
      'Insufficient stock for $productName: requested $requested, only $available available';
}

class SaleRepository {
  Future<Database> get _db async => DBHelper.instance.database;

  /// Confirms a sale: writes the transaction, its line items, deducts stock,
  /// and logs stock movements — all inside a single atomic DB transaction.
  ///
  /// [allowNegativeStock] mirrors the store's `settings` toggle; when false,
  /// checkout is aborted (nothing is written) if any line exceeds live stock.
  Future<SaleTransaction> checkout({
    required List<CartLine> cartLines,
    required PaymentType paymentType,
    required double amountTendered,
    String? buyerId,
    bool allowNegativeStock = false,
  }) async {
    if (cartLines.isEmpty) {
      throw ArgumentError('Cannot checkout an empty cart');
    }

    final db = await _db;
    final now = DateTime.now();
    final txnId = _uuid.v4();

    final subtotal = cartLines.fold<double>(0, (sum, line) => sum + line.lineTotal);
    final total = subtotal; // extend here if discounts/taxes are added later
    final change = paymentType == PaymentType.cash ? (amountTendered - total) : 0.0;

    final status = paymentType == PaymentType.credit && amountTendered < total
        ? TransactionStatus.pendingCredit
        : TransactionStatus.completed;

    await db.transaction((txn) async {
      // 1. Re-validate live stock inside the transaction to avoid race conditions
      //    (e.g. two cashiers on the same device, or a restock happening mid-checkout).
      for (final line in cartLines) {
        final rows = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [line.product.id],
          limit: 1,
        );
        if (rows.isEmpty) {
          throw InsufficientStockException(line.product.name, 0, line.qty);
        }
        final liveStock = (rows.first['stock_qty'] as num).toDouble();
        if (!allowNegativeStock && liveStock < line.qty) {
          throw InsufficientStockException(line.product.name, liveStock, line.qty);
        }
      }

      // 2. Insert transaction header
      await txn.insert('transactions', {
        'id': txnId,
        'subtotal': subtotal,
        'total': total,
        'amount_tendered': amountTendered,
        'change_amount': change,
        'payment_type': paymentTypeToStr(paymentType),
        'status': statusToStr(status),
        'buyer_id': buyerId,
        'void_reason': null,
        'synced_flag': 0,
        'created_at': now.toIso8601String(),
      });

      // 3. Insert line items + deduct stock + log movement, per line
      for (final line in cartLines) {
        final itemId = _uuid.v4();
        await txn.insert('transaction_items', {
          'id': itemId,
          'transaction_id': txnId,
          'product_id': line.product.id,
          'qty': line.qty,
          'unit_price': line.product.sellPrice,
          'line_total': line.lineTotal,
        });

        await txn.rawUpdate(
          'UPDATE products SET stock_qty = stock_qty - ?, updated_at = ? WHERE id = ?',
          [line.qty, now.toIso8601String(), line.product.id],
        );

        await txn.insert('stock_movements', {
          'id': _uuid.v4(),
          'product_id': line.product.id,
          'type': 'sale',
          'qty': -line.qty,
          'reference_id': txnId,
          'notes': null,
          'created_at': now.toIso8601String(),
        });
      }

      // 4. Credit handling: update buyer balance + log initial credit_payment (if any down payment)
      if (paymentType == PaymentType.credit || paymentType == PaymentType.partial) {
        if (buyerId == null) {
          throw ArgumentError('buyerId is required for credit/partial payments');
        }
        final balanceDue = total - amountTendered;
        await txn.rawUpdate(
          'UPDATE buyers SET total_outstanding_balance = total_outstanding_balance + ? WHERE id = ?',
          [balanceDue, buyerId],
        );
        if (amountTendered > 0) {
          await txn.insert('credit_payments', {
            'id': _uuid.v4(),
            'transaction_id': txnId,
            'buyer_id': buyerId,
            'amount_paid': amountTendered,
            'notes': 'Down payment at checkout',
            'created_at': now.toIso8601String(),
          });
        }
      }
    });

    return SaleTransaction(
      id: txnId,
      subtotal: subtotal,
      total: total,
      amountTendered: amountTendered,
      changeAmount: change,
      paymentType: paymentType,
      status: status,
      buyerId: buyerId,
      createdAt: now,
    );
  }

  /// Reverses a completed sale: restores stock, logs a void_return movement,
  /// and marks the transaction voided. Original rows are never deleted
  /// (audit trail preserved).
  Future<void> voidTransaction({
    required String transactionId,
    required String reason,
  }) async {
    final db = await _db;
    final now = DateTime.now();

    await db.transaction((txn) async {
      final txnRows = await txn.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
        limit: 1,
      );
      if (txnRows.isEmpty) {
        throw ArgumentError('Transaction not found: $transactionId');
      }
      final currentStatus = txnRows.first['status'] as String;
      if (currentStatus == 'voided') {
        throw StateError('Transaction is already voided');
      }

      final items = await txn.query(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
      );

      for (final item in items) {
        final productId = item['product_id'] as String;
        final qty = (item['qty'] as num).toDouble();

        await txn.rawUpdate(
          'UPDATE products SET stock_qty = stock_qty + ?, updated_at = ? WHERE id = ?',
          [qty, now.toIso8601String(), productId],
        );

        await txn.insert('stock_movements', {
          'id': _uuid.v4(),
          'product_id': productId,
          'type': 'void_return',
          'qty': qty,
          'reference_id': transactionId,
          'notes': 'Void: $reason',
          'created_at': now.toIso8601String(),
        });
      }

      // If this was a credit sale, reverse the buyer's outstanding balance too
      final buyerId = txnRows.first['buyer_id'] as String?;
      if (buyerId != null) {
        final total = (txnRows.first['total'] as num).toDouble();
        final tendered = (txnRows.first['amount_tendered'] as num).toDouble();
        final outstandingFromThisSale = total - tendered;
        if (outstandingFromThisSale > 0) {
          await txn.rawUpdate(
            'UPDATE buyers SET total_outstanding_balance = total_outstanding_balance - ? WHERE id = ?',
            [outstandingFromThisSale, buyerId],
          );
        }
      }

      await txn.update(
        'transactions',
        {'status': 'voided', 'void_reason': reason},
        where: 'id = ?',
        whereArgs: [transactionId],
      );
    });
  }

  /// Records an installment payment toward a buyer's utang, and marks the
  /// originating transaction 'settled' once the full balance is cleared.
  Future<void> addCreditPayment({
    required String transactionId,
    required String buyerId,
    required double amount,
    String? notes,
  }) async {
    final db = await _db;
    final now = DateTime.now();

    await db.transaction((txn) async {
      await txn.insert('credit_payments', {
        'id': _uuid.v4(),
        'transaction_id': transactionId,
        'buyer_id': buyerId,
        'amount_paid': amount,
        'notes': notes,
        'created_at': now.toIso8601String(),
      });

      await txn.rawUpdate(
        'UPDATE buyers SET total_outstanding_balance = total_outstanding_balance - ? WHERE id = ?',
        [amount, buyerId],
      );

      final buyerRows = await txn.query(
        'buyers',
        where: 'id = ?',
        whereArgs: [buyerId],
        limit: 1,
      );
      final remaining = (buyerRows.first['total_outstanding_balance'] as num).toDouble();

      // Only flip this specific transaction to 'settled' if paying it off
      // fully clears the buyer's balance tied to it. For simplicity here we
      // check the transaction's own remaining balance rather than the buyer's
      // total (a buyer may have multiple open credit transactions).
      final txnRows = await txn.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
        limit: 1,
      );
      if (txnRows.isNotEmpty) {
        final total = (txnRows.first['total'] as num).toDouble();
        final paidRows = await txn.rawQuery(
          'SELECT COALESCE(SUM(amount_paid), 0) as paid FROM credit_payments WHERE transaction_id = ?',
          [transactionId],
        );
        final totalPaid = (paidRows.first['paid'] as num).toDouble();
        if (totalPaid >= total) {
          await txn.update(
            'transactions',
            {'status': 'settled'},
            where: 'id = ?',
            whereArgs: [transactionId],
          );
        }
      }

      // remaining is unused beyond the check above but kept for potential
      // future use (e.g. triggering a "fully paid" notification)
      // ignore: unnecessary_statements
      remaining;
    });
  }
}
