import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/week_range.dart';
import '../../../domain/entities/inventory_document.dart';
import '../../../domain/repositories/inventory_repository.dart';
import '../../bloc/warehouse/warehouse_cubit.dart';
import '../../bloc/warehouse/warehouse_state.dart';
import 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  InventoryCubit({
    required InventoryRepository inventoryRepository,
    required WarehouseCubit warehouseCubit,
  })  : _inventoryRepository = inventoryRepository,
        _warehouseCubit = warehouseCubit,
        super(const InventoryInitial());

  final InventoryRepository _inventoryRepository;
  final WarehouseCubit _warehouseCubit;

  Future<void> loadInventories(String warehouseId) async {
    emit(const InventoryLoading());
    try {
      final week = _weekFromStateOrCurrent();
      final documents = await _fetchInventories(warehouseId, week);
      emit(
        InventoryLoaded(
          documents: documents,
          warehouseId: warehouseId,
          weekStart: week.start,
          weekEnd: week.end,
        ),
      );
    } catch (e) {
      emit(InventoryFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refreshInventories(String warehouseId) async {
    try {
      final week = _weekFromStateOrCurrent();
      final documents = await _fetchInventories(warehouseId, week);
      emit(
        InventoryLoaded(
          documents: documents,
          warehouseId: warehouseId,
          weekStart: week.start,
          weekEnd: week.end,
        ),
      );
    } catch (e) {
      emit(InventoryFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> setWeekFromDate(DateTime selectedDate, String warehouseId) async {
    final week = WeekRange.fromDate(selectedDate);
    final current = state;
    if (current is InventoryLoaded) {
      emit(
        InventoryLoaded(
          documents: current.documents,
          warehouseId: warehouseId,
          weekStart: week.start,
          weekEnd: week.end,
        ),
      );
    }

    try {
      final documents = await _fetchInventories(warehouseId, week);
      emit(
        InventoryLoaded(
          documents: documents,
          warehouseId: warehouseId,
          weekStart: week.start,
          weekEnd: week.end,
        ),
      );
    } catch (e) {
      emit(InventoryFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refreshCurrentWarehouse() async {
    final warehouseState = _warehouseCubit.state;
    if (warehouseState is WarehouseLoaded) {
      await loadInventories(warehouseState.selectedWarehouse.id);
    }
  }

  WeekRange _weekFromStateOrCurrent() {
    final previous = state;
    if (previous is InventoryLoaded) {
      return WeekRange(start: previous.weekStart, end: previous.weekEnd);
    }
    return WeekRange.current();
  }

  Future<List<InventoryDocument>> _fetchInventories(
    String warehouseId,
    WeekRange week,
  ) async {
    return _inventoryRepository.getInventories(
      warehouseId: warehouseId,
      date: week.start,
    );
  }
}
