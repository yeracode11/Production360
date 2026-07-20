import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/week_range.dart';
import '../../../domain/entities/production_document.dart';
import '../../../domain/repositories/production_repository.dart';
import '../../bloc/warehouse/warehouse_cubit.dart';
import '../../bloc/warehouse/warehouse_state.dart';
import 'production_state.dart';

class ProductionCubit extends Cubit<ProductionState> {
  ProductionCubit({
    required ProductionRepository productionRepository,
    required WarehouseCubit warehouseCubit,
  })  : _productionRepository = productionRepository,
        _warehouseCubit = warehouseCubit,
        super(const ProductionInitial());

  final ProductionRepository _productionRepository;
  final WarehouseCubit _warehouseCubit;

  Future<void> loadProductions(String warehouseId) async {
    emit(const ProductionLoading());
    try {
      final week = _weekFromStateOrCurrent();
      final documents = await _fetchProductions(warehouseId, week);
      emit(
        ProductionLoaded(
          documents: documents,
          warehouseId: warehouseId,
          weekStart: week.start,
          weekEnd: week.end,
        ),
      );
    } catch (e) {
      emit(ProductionFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refreshProductions(String warehouseId) async {
    try {
      final week = _weekFromStateOrCurrent();
      final documents = await _fetchProductions(warehouseId, week);
      emit(
        ProductionLoaded(
          documents: documents,
          warehouseId: warehouseId,
          weekStart: week.start,
          weekEnd: week.end,
        ),
      );
    } catch (e) {
      emit(ProductionFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> setWeekFromDate(
    DateTime selectedDate,
    String warehouseId,
  ) async {
    final week = WeekRange.fromDate(selectedDate);
    final current = state;
    if (current is ProductionLoaded) {
      emit(
        ProductionLoaded(
          documents: current.documents,
          warehouseId: warehouseId,
          weekStart: week.start,
          weekEnd: week.end,
        ),
      );
    }

    try {
      final documents = await _fetchProductions(warehouseId, week);
      emit(
        ProductionLoaded(
          documents: documents,
          warehouseId: warehouseId,
          weekStart: week.start,
          weekEnd: week.end,
        ),
      );
    } catch (e) {
      emit(ProductionFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refreshCurrentWarehouse() async {
    final warehouseState = _warehouseCubit.state;
    if (warehouseState is WarehouseLoaded) {
      await loadProductions(warehouseState.selectedWarehouse.id);
    }
  }

  WeekRange _weekFromStateOrCurrent() {
    final previous = state;
    if (previous is ProductionLoaded) {
      return WeekRange(start: previous.weekStart, end: previous.weekEnd);
    }
    return WeekRange.current();
  }

  Future<List<ProductionDocument>> _fetchProductions(
    String warehouseId,
    WeekRange week,
  ) async {
    return _productionRepository.getProductions(
      warehouseId: warehouseId,
      date: week.start,
    );
  }
}
