import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/week_range.dart';
import '../../../domain/entities/stock_writeoff.dart';
import '../../../domain/repositories/writeoff_repository.dart';
import '../../bloc/warehouse/warehouse_cubit.dart';
import '../../bloc/warehouse/warehouse_state.dart';
import 'writeoffs_state.dart';

class WriteoffsCubit extends Cubit<WriteoffsState> {
  WriteoffsCubit({
    required WriteoffRepository writeoffRepository,
    required WarehouseCubit warehouseCubit,
  })  : _writeoffRepository = writeoffRepository,
        _warehouseCubit = warehouseCubit,
        super(const WriteoffsInitial());

  final WriteoffRepository _writeoffRepository;
  final WarehouseCubit _warehouseCubit;

  Future<void> loadWriteoffs(String warehouseId) async {
    emit(const WriteoffsLoading());
    try {
      final week = _weekFromStateOrCurrent();
      final writeoffs = await _fetchWriteoffs(warehouseId, week);
      emit(
        WriteoffsLoaded(
          writeoffs: writeoffs,
          warehouseId: warehouseId,
          weekStart: week.start,
          weekEnd: week.end,
        ),
      );
    } catch (e) {
      emit(WriteoffsFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refreshWriteoffs(String warehouseId) async {
    try {
      final week = _weekFromStateOrCurrent();
      final writeoffs = await _fetchWriteoffs(warehouseId, week);
      emit(
        WriteoffsLoaded(
          writeoffs: writeoffs,
          warehouseId: warehouseId,
          weekStart: week.start,
          weekEnd: week.end,
        ),
      );
    } catch (e) {
      emit(WriteoffsFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> setWeekFromDate(DateTime selectedDate, String warehouseId) async {
    final week = WeekRange.fromDate(selectedDate);
    final current = state;
    if (current is WriteoffsLoaded) {
      emit(
        WriteoffsLoaded(
          writeoffs: current.writeoffs,
          warehouseId: warehouseId,
          weekStart: week.start,
          weekEnd: week.end,
        ),
      );
    }

    try {
      final writeoffs = await _fetchWriteoffs(warehouseId, week);
      emit(
        WriteoffsLoaded(
          writeoffs: writeoffs,
          warehouseId: warehouseId,
          weekStart: week.start,
          weekEnd: week.end,
        ),
      );
    } catch (e) {
      emit(WriteoffsFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refreshCurrentWarehouse() async {
    final warehouseState = _warehouseCubit.state;
    if (warehouseState is WarehouseLoaded) {
      await loadWriteoffs(warehouseState.selectedWarehouse.id);
    }
  }

  WeekRange _weekFromStateOrCurrent() {
    final previous = state;
    if (previous is WriteoffsLoaded) {
      return WeekRange(start: previous.weekStart, end: previous.weekEnd);
    }
    return WeekRange.current();
  }

  Future<List<StockWriteoff>> _fetchWriteoffs(
    String warehouseId,
    WeekRange week,
  ) async {
    return _writeoffRepository.getWriteoffs(
      warehouseId: warehouseId,
      date: week.start,
    );
  }
}
