import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/week_range.dart';
import '../../../domain/entities/internal_transfer.dart';
import '../../../domain/repositories/transfer_repository.dart';
import '../../bloc/warehouse/warehouse_cubit.dart';
import '../../bloc/warehouse/warehouse_state.dart';
import 'transfers_state.dart';

class TransfersCubit extends Cubit<TransfersState> {
  TransfersCubit({
    required TransferRepository transferRepository,
    required WarehouseCubit warehouseCubit,
  })  : _transferRepository = transferRepository,
        _warehouseCubit = warehouseCubit,
        super(const TransfersInitial());

  final TransferRepository _transferRepository;
  final WarehouseCubit _warehouseCubit;

  Future<void> loadTransfers(String warehouseId) async {
    emit(const TransfersLoading());
    try {
      final week = _weekFromStateOrCurrent();
      final transfers = await _fetchTransfers(warehouseId, week);
      emit(
        TransfersLoaded(
          transfers: transfers,
          warehouseId: warehouseId,
          weekStart: week.start,
          weekEnd: week.end,
        ),
      );
    } catch (e) {
      emit(TransfersFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refreshTransfers(String warehouseId) async {
    try {
      final week = _weekFromStateOrCurrent();
      final transfers = await _fetchTransfers(warehouseId, week);
      emit(
        TransfersLoaded(
          transfers: transfers,
          warehouseId: warehouseId,
          weekStart: week.start,
          weekEnd: week.end,
        ),
      );
    } catch (e) {
      emit(TransfersFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> setWeekFromDate(DateTime selectedDate, String warehouseId) async {
    final week = WeekRange.fromDate(selectedDate);
    final current = state;
    if (current is TransfersLoaded) {
      emit(
        TransfersLoaded(
          transfers: current.transfers,
          warehouseId: warehouseId,
          weekStart: week.start,
          weekEnd: week.end,
        ),
      );
    }

    try {
      final transfers = await _fetchTransfers(warehouseId, week);
      emit(
        TransfersLoaded(
          transfers: transfers,
          warehouseId: warehouseId,
          weekStart: week.start,
          weekEnd: week.end,
        ),
      );
    } catch (e) {
      emit(TransfersFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refreshCurrentWarehouse() async {
    final warehouseState = _warehouseCubit.state;
    if (warehouseState is WarehouseLoaded) {
      await loadTransfers(warehouseState.selectedWarehouse.id);
    }
  }

  WeekRange _weekFromStateOrCurrent() {
    final previous = state;
    if (previous is TransfersLoaded) {
      return WeekRange(start: previous.weekStart, end: previous.weekEnd);
    }
    return WeekRange.current();
  }

  Future<List<InternalTransfer>> _fetchTransfers(
    String warehouseId,
    WeekRange week,
  ) async {
    return _transferRepository.getTransfers(
      warehouseId: warehouseId,
      date: week.start,
    );
  }
}
