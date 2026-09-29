import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/week_range.dart';
import '../../../domain/entities/return_document.dart';
import '../../../domain/repositories/return_repository.dart';
import '../../bloc/warehouse/warehouse_cubit.dart';
import '../../bloc/warehouse/warehouse_state.dart';
import 'returns_state.dart';

class ReturnsCubit extends Cubit<ReturnsState> {
  ReturnsCubit({
    required ReturnRepository returnRepository,
    required WarehouseCubit warehouseCubit,
  })  : _returnRepository = returnRepository,
        _warehouseCubit = warehouseCubit,
        super(const ReturnsInitial());

  final ReturnRepository _returnRepository;
  final WarehouseCubit _warehouseCubit;

  Future<void> loadReturns(String warehouseId) async {
    emit(const ReturnsLoading());
    try {
      final week = _weekFromStateOrCurrent();
      final returns = await _fetchReturns(warehouseId, week);
      emit(
        ReturnsLoaded(
          returns: returns,
          warehouseId: warehouseId,
          weekStart: week.start,
          weekEnd: week.end,
        ),
      );
    } catch (e) {
      emit(ReturnsFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refreshReturns(String warehouseId) async {
    try {
      final week = _weekFromStateOrCurrent();
      final returns = await _fetchReturns(warehouseId, week);
      emit(
        ReturnsLoaded(
          returns: returns,
          warehouseId: warehouseId,
          weekStart: week.start,
          weekEnd: week.end,
        ),
      );
    } catch (e) {
      emit(ReturnsFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> setWeekFromDate(DateTime selectedDate, String warehouseId) async {
    final week = WeekRange.fromDate(selectedDate);
    final current = state;
    if (current is ReturnsLoaded) {
      emit(
        ReturnsLoaded(
          returns: current.returns,
          warehouseId: warehouseId,
          weekStart: week.start,
          weekEnd: week.end,
        ),
      );
    }

    try {
      final returns = await _fetchReturns(warehouseId, week);
      emit(
        ReturnsLoaded(
          returns: returns,
          warehouseId: warehouseId,
          weekStart: week.start,
          weekEnd: week.end,
        ),
      );
    } catch (e) {
      emit(ReturnsFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refreshCurrentWarehouse() async {
    final warehouseState = _warehouseCubit.state;
    if (warehouseState is WarehouseLoaded) {
      await loadReturns(warehouseState.selectedWarehouse.id);
    }
  }

  WeekRange _weekFromStateOrCurrent() {
    final previous = state;
    if (previous is ReturnsLoaded) {
      return WeekRange(start: previous.weekStart, end: previous.weekEnd);
    }
    return WeekRange.current();
  }

  Future<List<ReturnDocument>> _fetchReturns(
    String warehouseId,
    WeekRange week,
  ) async {
    return _returnRepository.getReturns(
      warehouseId: warehouseId,
      date: week.start,
    );
  }
}
