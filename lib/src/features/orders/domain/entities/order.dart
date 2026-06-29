enum OrderStatus {
  pending,
  preparing,
  ready,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

class OrderItem {
  const OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  final int? id;
  final int? orderId;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  double get subtotal => unitPrice * quantity;

  OrderItem copyWith({
    int? id,
    int? orderId,
    int? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}

class Order {
  const Order({
    this.id,
    required this.orderNumber,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.items = const [],
  });

  final int? id;
  final String orderNumber;
  final double totalPrice;
  final OrderStatus status;
  final DateTime createdAt;
  final List<OrderItem> items;

  Order copyWith({
    int? id,
    String? orderNumber,
    double? totalPrice,
    OrderStatus? status,
    DateTime? createdAt,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}
