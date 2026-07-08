import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../menu/presentation/providers/menu_providers.dart';
import '../../../menu/presentation/widgets/admin_scaffold.dart';
import '../../../menu/presentation/widgets/error_panel.dart';
import '../../domain/entities/order.dart';
import '../providers/order_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(allOrdersProvider);
    final productsState = ref.watch(productsControllerProvider);
    final categoriesState = ref.watch(categoriesControllerProvider);

    return AdminPageLayout(
      title: 'Dashboard',
      subtitle: 'Track sales, queue health, and menu performance.',
      child: ordersState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorPanel(
          message: error.toString(),
          onRetry: () => ref.invalidate(allOrdersProvider),
        ),
        data: (orders) {
          final activeOrders = orders
              .where((order) => order.status != OrderStatus.cancelled)
              .toList();
          final today = DateTime.now();
          final todaysOrders = activeOrders.where((order) {
            return order.createdAt.year == today.year &&
                order.createdAt.month == today.month &&
                order.createdAt.day == today.day;
          }).toList();
          final todayRevenue = todaysOrders.fold(
            0.0,
            (sum, order) => sum + order.totalPrice,
          );
          final totalRevenue = activeOrders.fold(
            0.0,
            (sum, order) => sum + order.totalPrice,
          );
          final averageTicket = activeOrders.isEmpty
              ? 0.0
              : totalRevenue / activeOrders.length;
          final queueCount = orders.where((order) {
            return order.status == OrderStatus.pending ||
                order.status == OrderStatus.preparing ||
                order.status == OrderStatus.ready;
          }).length;

          final productCount = productsState.maybeWhen(
            data: (products) => products.length,
            orElse: () => 0,
          );
          final categoryCount = categoriesState.maybeWhen(
            data: (categories) => categories.length,
            orElse: () => 0,
          );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allOrdersProvider);
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _KpiGrid(
                  cards: [
                    _KpiData(
                      icon: Icons.today,
                      label: 'Today Sales',
                      value: '${todayRevenue.toStringAsFixed(2)} TND',
                      helper: '${todaysOrders.length} orders',
                    ),
                    _KpiData(
                      icon: Icons.receipt_long,
                      label: 'All Orders',
                      value: '${orders.length}',
                      helper: '$queueCount active',
                    ),
                    _KpiData(
                      icon: Icons.payments,
                      label: 'Average Ticket',
                      value: '${averageTicket.toStringAsFixed(2)} TND',
                      helper: 'excluding cancelled',
                    ),
                    _KpiData(
                      icon: Icons.restaurant_menu,
                      label: 'Menu',
                      value: '$productCount items',
                      helper: '$categoryCount categories',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _StatusOverview(orders: orders),
                const SizedBox(height: 16),
                _BestSellers(orders: activeOrders),
                const SizedBox(height: 16),
                _DailyRevenue(orders: activeOrders),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KpiData {
  const _KpiData({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
  });

  final IconData icon;
  final String label;
  final String value;
  final String helper;
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.cards});

  final List<_KpiData> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 720 ? 2 : 4;
        return GridView.builder(
          itemCount: cards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: constraints.maxWidth < 520 ? 1.25 : 1.75,
          ),
          itemBuilder: (context, index) => _KpiCard(data: cards[index]),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});

  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(data.icon, size: 24),
            const Spacer(),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              data.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              data.helper,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOverview extends StatelessWidget {
  const _StatusOverview({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Status',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in OrderStatus.values)
                  _StatusPill(
                    status: status,
                    count: orders.where((o) => o.status == status).length,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.count});

  final OrderStatus status;
  final int count;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        child: Text('$count', style: const TextStyle(fontSize: 11)),
      ),
      label: Text(status.label),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      backgroundColor: color.withValues(alpha: 0.08),
    );
  }
}

class _BestSellers extends StatelessWidget {
  const _BestSellers({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final totals = <String, int>{};
    for (final order in orders) {
      for (final item in order.items) {
        totals[item.productName] =
            (totals[item.productName] ?? 0) + item.quantity;
      }
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = entries.take(6).toList();
    final maxCount = topEntries.isEmpty ? 1 : topEntries.first.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Best-Selling Products',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (topEntries.isEmpty)
              const Text('No product sales yet.')
            else
              for (final entry in topEntries) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('${entry.value} sold'),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: entry.value / maxCount),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _DailyRevenue extends StatelessWidget {
  const _DailyRevenue({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('EEE');
    final today = DateTime.now();
    final days = List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final revenue = orders
          .where((order) {
            return order.createdAt.year == date.year &&
                order.createdAt.month == date.month &&
                order.createdAt.day == date.day;
          })
          .fold(0.0, (sum, order) => sum + order.totalPrice);
      return (label: formatter.format(date), revenue: revenue);
    });
    final maxRevenue = days.fold(0.0, (max, day) {
      return day.revenue > max ? day.revenue : max;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 7 Days',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final day in days)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              day.revenue.toStringAsFixed(0),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Flexible(
                              child: FractionallySizedBox(
                                heightFactor: maxRevenue <= 0
                                    ? 0.02
                                    : (day.revenue / maxRevenue)
                                          .clamp(0.02, 1.0)
                                          .toDouble(),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const SizedBox(width: double.infinity),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              day.label,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
