import '../entities/order.dart';

abstract interface class OrderRepository {
  Future<Order> saveOrder({
    required String orderNumber,
    required double totalPrice,
    required List<OrderItem> items,
  });

  Future<List<Order>> getOrders();

  Future<Order?> getOrderByNumber(String orderNumber);

  Future<void> updateOrderStatus(int orderId, OrderStatus status);
}
