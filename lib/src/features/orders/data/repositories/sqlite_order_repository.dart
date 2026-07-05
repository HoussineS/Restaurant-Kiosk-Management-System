import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_local_data_source.dart';

class SqliteOrderRepository implements OrderRepository {
  const SqliteOrderRepository(this._dataSource);

  final OrderLocalDataSource _dataSource;

  @override
  Future<Order> saveOrder({
    required String orderNumber,
    required double totalPrice,
    required List<OrderItem> items,
  }) {
    return _dataSource.insertOrder(
      orderNumber: orderNumber,
      totalPrice: totalPrice,
      items: items,
    );
  }

  @override
  Future<List<Order>> getOrders({DateTime? startDate, DateTime? endDate}) => 
    _dataSource.getOrders(startDate: startDate, endDate: endDate);

  @override
  Future<Order?> getOrderByNumber(String orderNumber) async {
    final all = await _dataSource.getOrders();
    try {
      return all.firstWhere((o) => o.orderNumber == orderNumber);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateOrderStatus(int orderId, OrderStatus status) =>
      _dataSource.updateOrderStatus(orderId, status);

  @override
  Future<void> deleteOrder(int orderId) => _dataSource.deleteOrder(orderId);
}
