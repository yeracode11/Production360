import 'package:equatable/equatable.dart';

import '../../../core/utils/week_range.dart';
import '../../../domain/entities/production_document.dart';

sealed class ProductionState extends Equatable {
  const ProductionState();

  @override
  List<Object?> get props => [];
}

final class ProductionInitial extends ProductionState {
  const ProductionInitial();
}

final class ProductionLoading extends ProductionState {
  const ProductionLoading();
}

final class ProductionLoaded extends ProductionState {
  const ProductionLoaded({
    required this.documents,
    required this.warehouseId,
    required this.weekStart,
    required this.weekEnd,
  });

  final List<ProductionDocument> documents;
  final String warehouseId;
  final DateTime weekStart;
  final DateTime weekEnd;

  List<ProductionDocument> get documentsForWeek {
    return documents
        .where(
          (d) => WeekRange.containsDate(d.date, weekStart, weekEnd),
        )
        .toList();
  }

  @override
  List<Object?> get props => [documents, warehouseId, weekStart, weekEnd];
}

final class ProductionFailure extends ProductionState {
  const ProductionFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
