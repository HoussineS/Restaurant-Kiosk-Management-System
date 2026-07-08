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
      final orderId = await txn.insert('orders', {
        'order_number': orderNumber,
        'total_price': totalPrice,
        'status': OrderStatus.pending.name,
        'created_at': now.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.abort);

      final savedItems = <OrderItem>[];
      for (final item in items) {
        final itemId = await txn.insert('order_items', {
          'order_id': orderId,
          'product_id': item.productId,
          'product_name': item.productName,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
        });

        final savedModifiers = <OrderItemModifier>[];
        for (final mod in item.modifiers) {
          final modId = await txn.insert('order_item_modifiers', {
            'order_item_id': itemId,
            'name': mod.name,
            'extra_price': mod.extraPrice,
          });
          savedModifiers.add(mod.copyWith(id: modId, orderItemId: itemId));
        }

        savedItems.add(
          item.copyWith(
            id: itemId,
            orderId: orderId,
            modifiers: savedModifiers,
          ),
        );
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

  Future<List<Order>> getOrders({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final database = await _appDatabase.database;

    String? whereClause;
    List<Object?>? whereArgs;

    if (startDate != null && endDate != null) {
      whereClause = 'created_at >= ? AND created_at <= ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    } else if (startDate != null) {
      whereClause = 'created_at >= ?';
      whereArgs = [startDate.toIso8601String()];
    } else if (endDate != null) {
      whereClause = 'created_at <= ?';
      whereArgs = [endDate.toIso8601String()];
    }

    final orderRows = await database.query(
      'orders',
      where: whereClause,
      whereArgs: whereArgs,
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

      final items = <OrderItem>[];
      for (final r in itemRows) {
        final itemId = r['id'] as int;

        final modifierRows = await database.query(
          'order_item_modifiers',
          where: 'order_item_id = ?',
          whereArgs: [itemId],
        );

        final modifiers = modifierRows
            .map(
              (m) => OrderItemModifier(
                id: m['id'] as int,
                orderItemId: itemId,
                name: m['name'] as String,
                extraPrice: (m['extra_price'] as num).toDouble(),
              ),
            )
            .toList();

        items.add(
          OrderItem(
            id: itemId,
            orderId: orderId,
            productId: r['product_id'] as int,
            productName: r['product_name'] as String,
            quantity: r['quantity'] as int,
            unitPrice: (r['unit_price'] as num).toDouble(),
            modifiers: modifiers,
          ),
        );
      }

      orders.add(
        Order(
          id: orderId,
          orderNumber: row['order_number'] as String,
          totalPrice: (row['total_price'] as num).toDouble(),
          status: OrderStatus.fromString(row['status'] as String),
          createdAt: DateTime.parse(row['created_at'] as String),
          items: items,
        ),
      );
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

  Future<void> deleteOrder(int orderId) async {
    final database = await _appDatabase.database;
    await database.delete('orders', where: 'id = ?', whereArgs: [orderId]);
  }
}
