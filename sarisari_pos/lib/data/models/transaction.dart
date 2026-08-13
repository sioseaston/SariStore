enum PaymentType { cash, credit, partial }

enum TransactionStatus { completed, voided, settled, pendingCredit }

String paymentTypeToStr(PaymentType t) => t.name;
PaymentType paymentTypeFromStr(String s) =>
    PaymentType.values.firstWhere((e) => e.name == s, orElse: () => PaymentType.cash);

String statusToStr(TransactionStatus s) {
  switch (s) {
    case TransactionStatus.completed:
      return 'completed';
    case TransactionStatus.voided:
      return 'voided';
    case TransactionStatus.settled:
      return 'settled';
    case TransactionStatus.pendingCredit:
      return 'pending_credit';
  }
}

TransactionStatus statusFromStr(String s) {
  switch (s) {
    case 'voided':
      return TransactionStatus.voided;
    case 'settled':
      return TransactionStatus.settled;
    case 'pending_credit':
      return TransactionStatus.pendingCredit;
    default:
      return TransactionStatus.completed;
  }
}

class SaleTransaction {
  final String id;
  final double subtotal;
  final double total;
  final double amountTendered;
  final double changeAmount;
  final PaymentType paymentType;
  final TransactionStatus status;
  final String? buyerId;
  final String? voidReason;
  final bool synced;
  final DateTime createdAt;

  SaleTransaction({
    required this.id,
    required this.subtotal,
    required this.total,
    this.amountTendered = 0,
    this.changeAmount = 0,
    required this.paymentType,
    this.status = TransactionStatus.completed,
    this.buyerId,
    this.voidReason,
    this.synced = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'subtotal': subtotal,
        'total': total,
        'amount_tendered': amountTendered,
        'change_amount': changeAmount,
        'payment_type': paymentTypeToStr(paymentType),
        'status': statusToStr(status),
        'buyer_id': buyerId,
        'void_reason': voidReason,
        'synced_flag': synced ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory SaleTransaction.fromMap(Map<String, dynamic> map) => SaleTransaction(
        id: map['id'] as String,
        subtotal: (map['subtotal'] as num).toDouble(),
        total: (map['total'] as num).toDouble(),
        amountTendered: (map['amount_tendered'] as num).toDouble(),
        changeAmount: (map['change_amount'] as num).toDouble(),
        paymentType: paymentTypeFromStr(map['payment_type'] as String),
        status: statusFromStr(map['status'] as String),
        buyerId: map['buyer_id'] as String?,
        voidReason: map['void_reason'] as String?,
        synced: (map['synced_flag'] as int) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class TransactionItem {
  final String id;
  final String transactionId;
  final String productId;
  final double qty;
  final double unitPrice;
  final double lineTotal;

  TransactionItem({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'transaction_id': transactionId,
        'product_id': productId,
        'qty': qty,
        'unit_price': unitPrice,
        'line_total': lineTotal,
      };

  factory TransactionItem.fromMap(Map<String, dynamic> map) => TransactionItem(
        id: map['id'] as String,
        transactionId: map['transaction_id'] as String,
        productId: map['product_id'] as String,
        qty: (map['qty'] as num).toDouble(),
        unitPrice: (map['unit_price'] as num).toDouble(),
        lineTotal: (map['line_total'] as num).toDouble(),
      );
}

class StockMovement {
  final String id;
  final String productId;
  final String type; // 'restock','sale','void_return','adjustment','spoilage'
  final double qty; // negative = deduction, positive = addition
  final String? referenceId;
  final String? notes;
  final DateTime createdAt;

  StockMovement({
    required this.id,
    required this.productId,
    required this.type,
    required this.qty,
    this.referenceId,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'product_id': productId,
        'type': type,
        'qty': qty,
        'reference_id': referenceId,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory StockMovement.fromMap(Map<String, dynamic> map) => StockMovement(
        id: map['id'] as String,
        productId: map['product_id'] as String,
        type: map['type'] as String,
        qty: (map['qty'] as num).toDouble(),
        referenceId: map['reference_id'] as String?,
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class Buyer {
  final String id;
  final String name;
  final String? contactNumber;
  final double totalOutstandingBalance;
  final DateTime createdAt;

  Buyer({
    required this.id,
    required this.name,
    this.contactNumber,
    this.totalOutstandingBalance = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'contact_number': contactNumber,
        'total_outstanding_balance': totalOutstandingBalance,
        'created_at': createdAt.toIso8601String(),
      };

  factory Buyer.fromMap(Map<String, dynamic> map) => Buyer(
        id: map['id'] as String,
        name: map['name'] as String,
        contactNumber: map['contact_number'] as String?,
        totalOutstandingBalance: (map['total_outstanding_balance'] as num).toDouble(),
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class CreditPayment {
  final String id;
  final String transactionId;
  final String buyerId;
  final double amountPaid;
  final String? notes;
  final DateTime createdAt;

  CreditPayment({
    required this.id,
    required this.transactionId,
    required this.buyerId,
    required this.amountPaid,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'transaction_id': transactionId,
        'buyer_id': buyerId,
        'amount_paid': amountPaid,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory CreditPayment.fromMap(Map<String, dynamic> map) => CreditPayment(
        id: map['id'] as String,
        transactionId: map['transaction_id'] as String,
        buyerId: map['buyer_id'] as String,
        amountPaid: (map['amount_paid'] as num).toDouble(),
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

/// A single line in the in-memory cart, before checkout.
/// Cart state is NOT persisted to DB until payment is confirmed.
class CartLine {
  final Product product;
  double qty;

  CartLine({required this.product, this.qty = 1});

  double get lineTotal => product.sellPrice * qty;
}
