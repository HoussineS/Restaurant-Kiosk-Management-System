import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/order_local_data_source.dart';
import '../../data/repositories/sqlite_order_repository.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../../../menu/domain/entities/product.dart';

// ─── Infrastructure providers ────────────────────────────────────────────────

final orderLocalDataSourceProvider = Provider<OrderLocalDataSource>((ref) {
  return OrderLocalDataSource(ref.watch(appDatabaseProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return SqliteOrderRepository(ref.watch(orderLocalDataSourceProvider));
});

// ─── Cart (in-memory, ephemeral) ─────────────────────────────────────────────

class CartNotifier extends Notifier<List<OrderItem>> {
  @override
  List<OrderItem> build() => [];

  void addProduct(Product product) {
    final productId = product.id;
    if (productId == null) return;

    final existingIndex = state.indexWhere((i) => i.productId == productId);
    if (existingIndex >= 0) {
      final updated = state[existingIndex].copyWith(
        quantity: state[existingIndex].quantity + 1,
      );
      state = [...state]..[existingIndex] = updated;
    } else {
      state = [
        ...state,
        OrderItem(
          orderId: null,
          productId: productId,
          productName: product.name,
          quantity: 1,
          unitPrice: product.price,
        ),
      ];
    }
  }

  void increaseQuantity(int productId) {
    state = state.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: item.quantity + 1);
      }
      return item;
    }).toList();
  }

  void decreaseQuantity(int productId) {
    final item = state.firstWhere((i) => i.productId == productId);
    if (item.quantity <= 1) {
      removeItem(productId);
    } else {
      state = state.map((i) {
        if (i.productId == productId) {
          return i.copyWith(quantity: i.quantity - 1);
        }
        return i;
      }).toList();
    }
  }

  void removeItem(int productId) {
    state = state.where((i) => i.productId != productId).toList();
  }

  void clear() {
    state = [];
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<OrderItem>>(
  CartNotifier.new,
);

// ─── Selected category (kiosk) ────────────────────────────────────────────────

class _SelectedCategoryNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? id) => state = id;
}

final selectedCategoryProvider =
    NotifierProvider<_SelectedCategoryNotifier, int?>(
      _SelectedCategoryNotifier.new,
    );

final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).fold(0.0, (sum, item) => sum + item.subtotal);
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, item) => sum + item.quantity);
});

// ─── Orders controller ────────────────────────────────────────────────────────

class OrdersController extends AsyncNotifier<List<Order>> {
  late final OrderRepository _repository;

  @override
  Future<List<Order>> build() {
    _repository = ref.watch(orderRepositoryProvider);
    return _repository.getOrders();
  }

  /// Generates the next order number (padded sequential integer).
  String _generateOrderNumber(List<Order> existing) {
    if (existing.isEmpty) return '#0001';
    final nums = existing.map((o) {
      final num = int.tryParse(o.orderNumber.replaceAll('#', ''));
      return num ?? 0;
    });
    final next = nums.reduce((a, b) => a > b ? a : b) + 1;
    return '#${next.toString().padLeft(4, '0')}';
  }

  Future<Order?> placeOrder(List<OrderItem> items) async {
    if (items.isEmpty) return null;
    final total = items.fold(0.0, (s, i) => s + i.subtotal);
    final currentOrders = state.asData?.value ?? [];
    final orderNumber = _generateOrderNumber(currentOrders);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.saveOrder(
        orderNumber: orderNumber,
        totalPrice: total,
        items: items,
      );
      return _repository.getOrders();
    });

    // Return the newly placed order from state
    return state.asData?.value.firstWhere(
      (o) => o.orderNumber == orderNumber,
      orElse: () => Order(
        orderNumber: orderNumber,
        totalPrice: total,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateStatus(int orderId, OrderStatus status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.updateOrderStatus(orderId, status);
      return _repository.getOrders();
    });
  }

  Future<void> deleteOrder(int orderId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteOrder(orderId);
      return _repository.getOrders();
    });
  }
}

final ordersControllerProvider =
    AsyncNotifierProvider<OrdersController, List<Order>>(
      OrdersController.new,
    );
