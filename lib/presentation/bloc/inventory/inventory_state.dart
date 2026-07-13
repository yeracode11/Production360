import 'package:equatable/equatable.dart';

import '../../../core/utils/week_range.dart';
import '../../../domain/entities/inventory_document.dart';

sealed class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

final class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

final class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

final class InventoryLoaded extends InventoryState {
  const InventoryLoaded({
    required this.documents,
    required this.warehouseId,
    required this.weekStart,
    required this.weekEnd,
  });

  final List<InventoryDocument> documents;
  final String warehouseId;
  final DateTime weekStart;
  final DateTime weekEnd;

  List<InventoryDocument> get documentsForWeek {
    return documents
        .where(
          (d) => WeekRange.containsDate(d.date, weekStart, weekEnd),
        )
        .toList();
  }

  @override
  List<Object?> get props => [documents, warehouseId, weekStart, weekEnd];
}

final class InventoryFailure extends InventoryState {
  const InventoryFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
