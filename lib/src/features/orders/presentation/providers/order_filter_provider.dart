import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderFilterNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;

  void setDateRange(DateTimeRange? range) {
    state = range;
  }
}

final orderFilterProvider = NotifierProvider<OrderFilterNotifier, DateTimeRange?>(
  OrderFilterNotifier.new,
);
