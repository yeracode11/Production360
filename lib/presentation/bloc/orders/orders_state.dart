import 'package:equatable/equatable.dart';

import '../../../core/utils/week_range.dart';
import '../../../domain/entities/order_request.dart';
import '../../../domain/enums/order_status.dart';

sealed class OrdersState extends Equatable {
  const OrdersState();

  @override
  List<Object?> get props => [];
}

final class OrdersInitial extends OrdersState {
  const OrdersInitial();
}

final class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

final class OrdersLoaded extends OrdersState {
  const OrdersLoaded({
    required this.orders,
    required this.outletId,
    required this.completedWeekStart,
    required this.completedWeekEnd,
  });

  final List<OrderRequest> orders;
  final String outletId;

  /// Начало выбранной недели для вкладки «Завершен» (Пн 00:00).
  final DateTime completedWeekStart;

  /// Конец выбранной недели (Вс 23:59:59).
  final DateTime completedWeekEnd;

  /// Завершённые заявки в выбранном недельном диапазоне (по дате отгрузки или создания).
  List<OrderRequest> get completedOrdersForWeek {
    return orders
        .where((o) => o.status == OrderStatus.completed)
        .where((o) {
          final filterDate = o.createdDate ?? o.deliveryDate;
          return WeekRange.containsDate(
            filterDate,
            completedWeekStart,
            completedWeekEnd,
          );
        })
        .toList();
  }

  /// Все завершённые заявки в загруженном списке (для подсказки в UI).
  int get completedOrdersTotal =>
      orders.where((o) => o.status == OrderStatus.completed).length;

  @override
  List<Object?> get props => [
        orders,
        outletId,
        completedWeekStart,
        completedWeekEnd,
      ];
}

final class OrdersFailure extends OrdersState {
  const OrdersFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
