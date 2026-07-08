import 'package:equatable/equatable.dart';

import '../../../core/utils/week_range.dart';
import '../../../domain/entities/stock_writeoff.dart';

sealed class WriteoffsState extends Equatable {
  const WriteoffsState();

  @override
  List<Object?> get props => [];
}

final class WriteoffsInitial extends WriteoffsState {
  const WriteoffsInitial();
}

final class WriteoffsLoading extends WriteoffsState {
  const WriteoffsLoading();
}

final class WriteoffsLoaded extends WriteoffsState {
  const WriteoffsLoaded({
    required this.writeoffs,
    required this.warehouseId,
    required this.weekStart,
    required this.weekEnd,
  });

  final List<StockWriteoff> writeoffs;
  final String warehouseId;
  final DateTime weekStart;
  final DateTime weekEnd;

  List<StockWriteoff> get writeoffsForWeek {
    return writeoffs
        .where(
          (w) => WeekRange.containsDate(w.date, weekStart, weekEnd),
        )
        .toList();
  }

  @override
  List<Object?> get props => [writeoffs, warehouseId, weekStart, weekEnd];
}

final class WriteoffsFailure extends WriteoffsState {
  const WriteoffsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
