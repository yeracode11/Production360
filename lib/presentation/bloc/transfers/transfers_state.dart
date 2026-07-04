import 'package:equatable/equatable.dart';

import '../../../core/utils/week_range.dart';
import '../../../domain/entities/internal_transfer.dart';

sealed class TransfersState extends Equatable {
  const TransfersState();

  @override
  List<Object?> get props => [];
}

final class TransfersInitial extends TransfersState {
  const TransfersInitial();
}

final class TransfersLoading extends TransfersState {
  const TransfersLoading();
}

final class TransfersLoaded extends TransfersState {
  const TransfersLoaded({
    required this.transfers,
    required this.warehouseId,
    required this.weekStart,
    required this.weekEnd,
  });

  final List<InternalTransfer> transfers;
  final String warehouseId;
  final DateTime weekStart;
  final DateTime weekEnd;

  List<InternalTransfer> get transfersForWeek {
    return transfers
        .where(
          (t) => WeekRange.containsDate(t.date, weekStart, weekEnd),
        )
        .toList();
  }

  @override
  List<Object?> get props => [transfers, warehouseId, weekStart, weekEnd];
}

final class TransfersFailure extends TransfersState {
  const TransfersFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
