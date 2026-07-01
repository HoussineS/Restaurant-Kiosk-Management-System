import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/order.dart';
import '../providers/order_providers.dart';
import 'pos_screen.dart';
import '../../../menu/presentation/widgets/admin_scaffold.dart';
import '../../../menu/presentation/widgets/error_panel.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(ordersControllerProvider);

    return AdminPageLayout(
      title: 'Order Management',
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'orders_fab',
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PosScreen())),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('New Order'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      child: ordersState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorPanel(
          message: error.toString(),
          onRetry: () => ref.invalidate(ordersControllerProvider),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.black26),
                  SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create a new order to get started.',
                    style: TextStyle(color: Colors.black38),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: orders.length,
            padding: const EdgeInsets.only(bottom: 80),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderCard(order: order);
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Status color mapping
    Color statusColor;
    switch (order.status) {
      case OrderStatus.pending:
        statusColor = Colors.orange;
        break;
      case OrderStatus.preparing:
        statusColor = Colors.blue;
        break;
      case OrderStatus.ready:
        statusColor = Colors.green;
        break;
      case OrderStatus.completed:
        statusColor = Colors.grey;
        break;
      case OrderStatus.cancelled:
        statusColor = Colors.red;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Order Number, Date, Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.orderNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${order.createdAt.year}-${order.createdAt.month.toString().padLeft(2, '0')}-${order.createdAt.day.toString().padLeft(2, '0')} ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const Spacer(),
                // Status Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<OrderStatus>(
                      value: order.status,
                      icon: Icon(Icons.arrow_drop_down, color: statusColor),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      items: OrderStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        );
                      }).toList(),
                      onChanged: (newStatus) {
                        if (newStatus != null && newStatus != order.status) {
                          ref
                              .read(ordersControllerProvider.notifier)
                              .updateStatus(order.id!, newStatus);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Items List
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${item.quantity}x',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.productName,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '${item.subtotal.toStringAsFixed(2)} TND',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Footer: Total & Delete Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _confirmDelete(context, ref, order),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red.shade400,
                  tooltip: 'Delete Order',
                ),
                Text(
                  'Total: ${order.totalPrice.toStringAsFixed(2)} TND',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Order order) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order?'),
        content: Text(
          'Are you sure you want to permanently delete ${order.orderNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(ordersControllerProvider.notifier)
                  .deleteOrder(order.id!);
              Navigator.of(ctx).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
