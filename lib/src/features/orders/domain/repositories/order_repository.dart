import '../entities/order.dart';

abstract interface class OrderRepository {
  Future<Order> saveOrder({
    required String orderNumber,
    required double totalPrice,
    required List<OrderItem> items,
  });

  Future<List<Order>> getOrders({DateTime? startDate, DateTime? endDate});

  Future<Order?> getOrderByNumber(String orderNumber);

  Future<void> updateOrderStatus(int orderId, OrderStatus status);

  Future<void> deleteOrder(int orderId);
}
