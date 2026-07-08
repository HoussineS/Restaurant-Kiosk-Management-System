import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/order.dart';
import '../providers/order_providers.dart';
import '../providers/order_filter_provider.dart';
import '../../utils/printer_service.dart';
import 'package:intl/intl.dart';
import 'pos_screen.dart';
import '../../../menu/presentation/widgets/admin_scaffold.dart';
import '../../../menu/presentation/widgets/error_panel.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(ordersControllerProvider);
    final dateRange = ref.watch(orderFilterProvider);

    return AdminPageLayout(
      title: 'Order Management',
      subtitle:
          'Search history, update statuses, reprint tickets, and run summaries.',
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OrdersToolbar(orders: orders, dateRange: dateRange),
              const SizedBox(height: 16),
              Expanded(
                child: orders.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.black26,
                            ),
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
                      )
                    : ListView.builder(
                        itemCount: orders.length,
                        padding: const EdgeInsets.only(bottom: 80),
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return _OrderCard(order: order);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrdersToolbar extends ConsumerWidget {
  const _OrdersToolbar({required this.orders, required this.dateRange});

  final List<Order> orders;
  final DateTimeRange? dateRange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStatus = ref.watch(orderStatusFilterProvider);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search order or product',
            ),
            onChanged: (value) =>
                ref.read(orderSearchProvider.notifier).setQuery(value),
          ),
        ),
        TextButton.icon(
          onPressed: () async {
            final range = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
              initialDateRange: dateRange,
            );
            if (range != null) {
              ref.read(orderFilterProvider.notifier).setDateRange(range);
            }
          },
          icon: const Icon(Icons.date_range),
          label: Text(
            dateRange == null
                ? 'Filter by Date'
                : '${DateFormat('MMM d').format(dateRange!.start)} - '
                      '${DateFormat('MMM d').format(dateRange!.end)}',
          ),
        ),
        DropdownButton<OrderStatus?>(
          value: selectedStatus,
          hint: const Text('All statuses'),
          items: [
            const DropdownMenuItem<OrderStatus?>(
              value: null,
              child: Text('All statuses'),
            ),
            for (final status in OrderStatus.values)
              DropdownMenuItem<OrderStatus?>(
                value: status,
                child: Text(status.label),
              ),
          ],
          onChanged: (status) =>
              ref.read(orderStatusFilterProvider.notifier).setStatus(status),
        ),
        if (dateRange != null || selectedStatus != null)
          OutlinedButton.icon(
            onPressed: () {
              ref.read(orderFilterProvider.notifier).setDateRange(null);
              ref.read(orderStatusFilterProvider.notifier).setStatus(null);
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear Filters'),
          ),
        if (orders.isNotEmpty)
          ElevatedButton.icon(
            onPressed: () => PrinterService.printSummary(
              orders,
              dateRange?.start,
              dateRange?.end,
            ),
            icon: const Icon(Icons.print),
            label: const Text('Print Summary'),
          ),
      ],
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
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
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
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
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _confirmDelete(context, ref, order),
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red.shade400,
                      tooltip: 'Delete Order',
                    ),
                    IconButton(
                      onPressed: () => PrinterService.printReceipt(order),
                      icon: const Icon(Icons.print_outlined),
                      tooltip: 'Print Receipt',
                    ),
                  ],
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
