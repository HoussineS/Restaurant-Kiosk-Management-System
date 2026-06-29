import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/order.dart';

class OrderLocalDataSource {
  const OrderLocalDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<Order> insertOrder({
    required String orderNumber,
    required double totalPrice,
    required List<OrderItem> items,
  }) async {
    final database = await _appDatabase.database;
    final now = DateTime.now();

    return database.transaction((txn) async {
      final orderId = await txn.insert(
        'orders',
        {
          'order_number': orderNumber,
          'total_price': totalPrice,
          'status': OrderStatus.pending.name,
          'created_at': now.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      final savedItems = <OrderItem>[];
      for (final item in items) {
        final itemId = await txn.insert('order_items', {
          'order_id': orderId,
          'product_id': item.productId,
          'product_name': item.productName,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
        });
        savedItems.add(item.copyWith(id: itemId, orderId: orderId));
      }

      return Order(
        id: orderId,
        orderNumber: orderNumber,
        totalPrice: totalPrice,
        status: OrderStatus.pending,
        createdAt: now,
        items: savedItems,
      );
    });
  }

  Future<List<Order>> getOrders() async {
    final database = await _appDatabase.database;
    final orderRows = await database.query(
      'orders',
      orderBy: 'created_at DESC',
    );

    final orders = <Order>[];
    for (final row in orderRows) {
      final orderId = row['id'] as int;
      final itemRows = await database.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );

      final items = itemRows.map((r) {
        return OrderItem(
          id: r['id'] as int,
          orderId: orderId,
          productId: r['product_id'] as int,
          productName: r['product_name'] as String,
          quantity: r['quantity'] as int,
          unitPrice: r['unit_price'] as double,
        );
      }).toList();

      orders.add(Order(
        id: orderId,
        orderNumber: row['order_number'] as String,
        totalPrice: row['total_price'] as double,
        status: OrderStatus.fromString(row['status'] as String),
        createdAt: DateTime.parse(row['created_at'] as String),
        items: items,
      ));
    }

    return orders;
  }

  Future<void> updateOrderStatus(int orderId, OrderStatus status) async {
    final database = await _appDatabase.database;
    await database.update(
      'orders',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }
}
