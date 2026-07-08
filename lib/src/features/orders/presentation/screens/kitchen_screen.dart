import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../menu/presentation/widgets/admin_scaffold.dart';
import '../../../menu/presentation/widgets/error_panel.dart';
import '../../domain/entities/order.dart';
import '../providers/order_providers.dart';

class KitchenScreen extends ConsumerWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(allOrdersProvider);

    return AdminPageLayout(
      title: 'Kitchen Queue',
      subtitle: 'Move orders through preparation and pickup.',
      child: ordersState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorPanel(
          message: error.toString(),
          onRetry: () => ref.invalidate(allOrdersProvider),
        ),
        data: (orders) {
          final activeOrders = orders.where((order) {
            return order.status == OrderStatus.pending ||
                order.status == OrderStatus.preparing ||
                order.status == OrderStatus.ready;
          }).toList();

          if (activeOrders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.soup_kitchen_outlined,
                    size: 64,
                    color: Colors.black26,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Kitchen queue is clear',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;
              final columns = [
                _KitchenColumn(
                  title: 'Pending',
                  status: OrderStatus.pending,
                  orders: activeOrders
                      .where((order) => order.status == OrderStatus.pending)
                      .toList(),
                ),
                _KitchenColumn(
                  title: 'Preparing',
                  status: OrderStatus.preparing,
                  orders: activeOrders
                      .where((order) => order.status == OrderStatus.preparing)
                      .toList(),
                ),
                _KitchenColumn(
                  title: 'Ready',
                  status: OrderStatus.ready,
                  orders: activeOrders
                      .where((order) => order.status == OrderStatus.ready)
                      .toList(),
                ),
              ];

              if (isNarrow) {
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: columns.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => columns[index],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < columns.length; index++) ...[
                    Expanded(child: columns[index]),
                    if (index != columns.length - 1) const SizedBox(width: 12),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _KitchenColumn extends StatelessWidget {
  const _KitchenColumn({
    required this.title,
    required this.status,
    required this.orders,
  });

  final String title;
  final OrderStatus status;
  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(_statusIcon(status), color: _statusColor(status)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: _statusColor(status).withValues(alpha: 0.12),
                  foregroundColor: _statusColor(status),
                  child: Text(
                    '${orders.length}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (orders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No orders')),
              )
            else
              ...orders.map((order) => _KitchenOrderCard(order: order)),
          ],
        ),
      ),
    );
  }
}

class _KitchenOrderCard extends ConsumerWidget {
  const _KitchenOrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elapsed = DateTime.now().difference(order.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                order.orderNumber,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${elapsed.inMinutes} min',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          Text(
            DateFormat('HH:mm').format(order.createdAt),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const Divider(height: 18),
          for (final item in order.items) ...[
            Text(
              '${item.quantity}x ${item.productName}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (item.modifiers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 2),
                child: Text(
                  item.modifiers.map((mod) => mod.name).join(', '),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 8),
          _KitchenActions(order: order),
        ],
      ),
    );
  }
}

class _KitchenActions extends ConsumerWidget {
  const _KitchenActions({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = _actionsFor(order.status);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final action in actions)
          FilledButton.icon(
            onPressed: () {
              ref
                  .read(ordersControllerProvider.notifier)
                  .updateStatus(order.id!, action.status);
            },
            icon: Icon(action.icon, size: 18),
            label: Text(action.label),
            style: FilledButton.styleFrom(
              backgroundColor: action.status == OrderStatus.cancelled
                  ? Colors.red
                  : Colors.black,
            ),
          ),
      ],
    );
  }

  List<_KitchenAction> _actionsFor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const [
          _KitchenAction(
            label: 'Start',
            icon: Icons.play_arrow,
            status: OrderStatus.preparing,
          ),
          _KitchenAction(
            label: 'Cancel',
            icon: Icons.close,
            status: OrderStatus.cancelled,
          ),
        ];
      case OrderStatus.preparing:
        return const [
          _KitchenAction(
            label: 'Ready',
            icon: Icons.check,
            status: OrderStatus.ready,
          ),
          _KitchenAction(
            label: 'Cancel',
            icon: Icons.close,
            status: OrderStatus.cancelled,
          ),
        ];
      case OrderStatus.ready:
        return const [
          _KitchenAction(
            label: 'Complete',
            icon: Icons.done_all,
            status: OrderStatus.completed,
          ),
        ];
      case OrderStatus.completed:
      case OrderStatus.cancelled:
        return const [];
    }
  }
}

class _KitchenAction {
  const _KitchenAction({
    required this.label,
    required this.icon,
    required this.status,
  });

  final String label;
  final IconData icon;
  final OrderStatus status;
}

IconData _statusIcon(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return Icons.hourglass_empty;
    case OrderStatus.preparing:
      return Icons.local_fire_department_outlined;
    case OrderStatus.ready:
      return Icons.room_service_outlined;
    case OrderStatus.completed:
      return Icons.done_all;
    case OrderStatus.cancelled:
      return Icons.cancel_outlined;
  }
}

Color _statusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return Colors.orange;
    case OrderStatus.preparing:
      return Colors.blue;
    case OrderStatus.ready:
      return Colors.green;
    case OrderStatus.completed:
      return Colors.grey;
    case OrderStatus.cancelled:
      return Colors.red;
  }
}
