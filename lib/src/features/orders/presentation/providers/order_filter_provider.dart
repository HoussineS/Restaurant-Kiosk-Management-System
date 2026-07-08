import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/order.dart';

class OrderFilterNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;

  void setDateRange(DateTimeRange? range) {
    state = range;
  }
}

final orderFilterProvider =
    NotifierProvider<OrderFilterNotifier, DateTimeRange?>(
      OrderFilterNotifier.new,
    );

class OrderSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) {
    state = value.trim();
  }
}

final orderSearchProvider = NotifierProvider<OrderSearchNotifier, String>(
  OrderSearchNotifier.new,
);

class OrderStatusFilterNotifier extends Notifier<OrderStatus?> {
  @override
  OrderStatus? build() => null;

  void setStatus(OrderStatus? status) {
    state = status;
  }
}

final orderStatusFilterProvider =
    NotifierProvider<OrderStatusFilterNotifier, OrderStatus?>(
      OrderStatusFilterNotifier.new,
    );
