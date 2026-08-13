class Product {
  final String id;
  final String? barcode;
  final String name;
  final String unit; // 'piece', 'sachet', 'kg', 'pack'
  final double costPrice;
  final double sellPrice;
  final double stockQty;
  final double reorderLevel;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    this.barcode,
    required this.name,
    required this.unit,
    this.costPrice = 0,
    required this.sellPrice,
    this.stockQty = 0,
    this.reorderLevel = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => stockQty <= reorderLevel;

  Map<String, dynamic> toMap() => {
        'id': id,
        'barcode': barcode,
        'name': name,
        'unit': unit,
        'cost_price': costPrice,
        'sell_price': sellPrice,
        'stock_qty': stockQty,
        'reorder_level': reorderLevel,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] as String,
        barcode: map['barcode'] as String?,
        name: map['name'] as String,
        unit: map['unit'] as String,
        costPrice: (map['cost_price'] as num).toDouble(),
        sellPrice: (map['sell_price'] as num).toDouble(),
        stockQty: (map['stock_qty'] as num).toDouble(),
        reorderLevel: (map['reorder_level'] as num).toDouble(),
        isActive: (map['is_active'] as int) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Product copyWith({
    String? name,
    String? unit,
    double? costPrice,
    double? sellPrice,
    double? stockQty,
    double? reorderLevel,
    bool? isActive,
  }) {
    return Product(
      id: id,
      barcode: barcode,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      costPrice: costPrice ?? this.costPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      stockQty: stockQty ?? this.stockQty,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
