import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/order_local_data_source.dart';
import '../../data/repositories/sqlite_order_repository.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../../../menu/domain/entities/product.dart';
import 'order_filter_provider.dart';

// ─── Infrastructure providers ────────────────────────────────────────────────

final orderLocalDataSourceProvider = Provider<OrderLocalDataSource>((ref) {
  return OrderLocalDataSource(ref.watch(appDatabaseProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return SqliteOrderRepository(ref.watch(orderLocalDataSourceProvider));
});

final allOrdersProvider = FutureProvider<List<Order>>((ref) {
  return ref.watch(orderRepositoryProvider).getOrders();
});

// ─── Cart (in-memory, ephemeral) ─────────────────────────────────────────────

class CartNotifier extends Notifier<List<OrderItem>> {
  @override
  List<OrderItem> build() => [];

  void addProduct(
    Product product, {
    List<ProductModifier> chosenModifiers = const [],
  }) {
    final productId = product.id;
    if (productId == null) return;

    final orderItemModifiers = chosenModifiers
        .map((m) => OrderItemModifier(name: m.name, extraPrice: m.extraPrice))
        .toList();

    // Check if an exact match (same product & same modifiers) exists
    final existingIndex = state.indexWhere((i) {
      if (i.productId != productId) return false;
      if (i.modifiers.length != orderItemModifiers.length) return false;
      // Simple name check is enough for equality here
      final existingNames = i.modifiers.map((m) => m.name).toSet();
      final newNames = orderItemModifiers.map((m) => m.name).toSet();
      return existingNames.containsAll(newNames) &&
          newNames.containsAll(existingNames);
    });

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
          modifiers: orderItemModifiers,
        ),
      ];
    }
  }

  void increaseQuantity(int index) {
    if (index < 0 || index >= state.length) return;
    final item = state[index];
    final updated = item.copyWith(quantity: item.quantity + 1);
    state = [...state]..[index] = updated;
  }

  void decreaseQuantity(int index) {
    if (index < 0 || index >= state.length) return;
    final item = state[index];
    if (item.quantity > 1) {
      final updated = item.copyWith(quantity: item.quantity - 1);
      state = [...state]..[index] = updated;
    } else {
      removeItem(index);
    }
  }

  void removeItem(int index) {
    if (index < 0 || index >= state.length) return;
    final newState = [...state];
    newState.removeAt(index);
    state = newState;
  }

  void clearCart() {
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

  Future<List<Order>> _fetchOrders() {
    final dateRange = ref.read(orderFilterProvider);
    final searchQuery = ref.read(orderSearchProvider).toLowerCase();
    final statusFilter = ref.read(orderStatusFilterProvider);
    DateTime? endDate = dateRange?.end;
    if (endDate != null) {
      endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    }
    return _repository
        .getOrders(startDate: dateRange?.start, endDate: endDate)
        .then((orders) {
          return orders.where((order) {
            final matchesStatus =
                statusFilter == null || order.status == statusFilter;
            final matchesSearch =
                searchQuery.isEmpty ||
                order.orderNumber.toLowerCase().contains(searchQuery) ||
                order.items.any(
                  (item) =>
                      item.productName.toLowerCase().contains(searchQuery),
                );
            return matchesStatus && matchesSearch;
          }).toList();
        });
  }

  @override
  Future<List<Order>> build() {
    _repository = ref.watch(orderRepositoryProvider);
    ref.watch(orderFilterProvider); // re-fetch when filter changes
    ref.watch(orderSearchProvider);
    ref.watch(orderStatusFilterProvider);
    return _fetchOrders();
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
    final currentOrders = await _repository.getOrders();
    final orderNumber = _generateOrderNumber(currentOrders);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.saveOrder(
        orderNumber: orderNumber,
        totalPrice: total,
        items: items,
      );
      ref.invalidate(allOrdersProvider);
      return _fetchOrders();
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
      ref.invalidate(allOrdersProvider);
      return _fetchOrders();
    });
  }

  Future<void> deleteOrder(int orderId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteOrder(orderId);
      ref.invalidate(allOrdersProvider);
      return _fetchOrders();
    });
  }
}

final ordersControllerProvider =
    AsyncNotifierProvider<OrdersController, List<Order>>(OrdersController.new);
