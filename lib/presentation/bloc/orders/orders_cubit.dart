import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/week_range.dart';
import '../../../domain/entities/order_request.dart';
import '../../../domain/repositories/order_repository.dart';
import '../../bloc/warehouse/warehouse_cubit.dart';
import '../../bloc/warehouse/warehouse_state.dart';
import 'orders_state.dart';

/// Loads orders for the currently selected warehouse.
class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit({
    required OrderRepository orderRepository,
    required WarehouseCubit warehouseCubit,
  })  : _orderRepository = orderRepository,
        _warehouseCubit = warehouseCubit,
        super(const OrdersInitial());

  final OrderRepository _orderRepository;
  final WarehouseCubit _warehouseCubit;

  Future<void> loadOrders(String warehouseId) async {
    emit(const OrdersLoading());
    try {
      final week = _weekFromStateOrCurrent();
      final orders = await _fetchMergedOrders(warehouseId, week);
      emit(
        OrdersLoaded(
          orders: orders,
          outletId: warehouseId,
          completedWeekStart: week.start,
          completedWeekEnd: week.end,
        ),
      );
    } catch (e) {
      emit(OrdersFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refreshOrders(String warehouseId) async {
    try {
      final week = _weekFromStateOrCurrent();
      final orders = await _fetchMergedOrders(warehouseId, week);
      emit(
        OrdersLoaded(
          orders: orders,
          outletId: warehouseId,
          completedWeekStart: week.start,
          completedWeekEnd: week.end,
        ),
      );
    } catch (e) {
      emit(OrdersFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Пересчитывает неделю по выбранному дню и подгружает заявки за этот период.
  Future<void> setCompletedWeekFromDate(DateTime selectedDate) async {
    final current = state;
    if (current is! OrdersLoaded) return;

    final week = WeekRange.fromDate(selectedDate);

    emit(
      OrdersLoaded(
        orders: current.orders,
        outletId: current.outletId,
        completedWeekStart: week.start,
        completedWeekEnd: week.end,
      ),
    );

    try {
      final orders = await _fetchMergedOrders(current.outletId, week);
      emit(
        OrdersLoaded(
          orders: orders,
          outletId: current.outletId,
          completedWeekStart: week.start,
          completedWeekEnd: week.end,
        ),
      );
    } catch (e) {
      emit(OrdersFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refreshCurrentWarehouse() async {
    final warehouseState = _warehouseCubit.state;
    if (warehouseState is WarehouseLoaded) {
      await loadOrders(warehouseState.selectedWarehouse.id);
    }
  }

  WeekRange _weekFromStateOrCurrent() {
    final previous = state;
    if (previous is OrdersLoaded) {
      return WeekRange(
        start: previous.completedWeekStart,
        end: previous.completedWeekEnd,
      );
    }
    return WeekRange.current();
  }

  /// Актуальные заявки + завершённые за выбранную неделю (отдельный запрос к 1С).
  Future<List<OrderRequest>> _fetchMergedOrders(
    String warehouseId,
    WeekRange week,
  ) async {
    final activeOrders = await _orderRepository.getOrders(outletId: warehouseId);

    try {
      final weekOrders = await _orderRepository.getOrders(
        outletId: warehouseId,
        weekDate: week.start,
      );
      return _mergeOrders(activeOrders, weekOrders);
    } catch (_) {
      // 1С может не поддерживать date — фильтруем локально.
      return activeOrders;
    }
  }

  List<OrderRequest> _mergeOrders(
    List<OrderRequest> primary,
    List<OrderRequest> secondary,
  ) {
    final map = {for (final order in primary) order.id: order};
    for (final order in secondary) {
      map[order.id] = order;
    }
    return map.values.toList();
  }
}
