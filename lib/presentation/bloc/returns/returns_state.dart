import 'package:equatable/equatable.dart';

import '../../../core/utils/week_range.dart';
import '../../../domain/entities/return_document.dart';

sealed class ReturnsState extends Equatable {
  const ReturnsState();

  @override
  List<Object?> get props => [];
}

final class ReturnsInitial extends ReturnsState {
  const ReturnsInitial();
}

final class ReturnsLoading extends ReturnsState {
  const ReturnsLoading();
}

final class ReturnsLoaded extends ReturnsState {
  const ReturnsLoaded({
    required this.returns,
    required this.warehouseId,
    required this.weekStart,
    required this.weekEnd,
  });

  final List<ReturnDocument> returns;
  final String warehouseId;
  final DateTime weekStart;
  final DateTime weekEnd;

  List<ReturnDocument> get returnsForWeek {
    return returns
        .where(
          (doc) => WeekRange.containsDate(doc.date, weekStart, weekEnd),
        )
        .toList();
  }

  @override
  List<Object?> get props => [returns, warehouseId, weekStart, weekEnd];
}

final class ReturnsFailure extends ReturnsState {
  const ReturnsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
