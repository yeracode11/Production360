import 'package:equatable/equatable.dart';

/// Завершение инвентаризации (POST /mobile/invent/create с docID).
class CompleteInventoryRequest extends Equatable {
  const CompleteInventoryRequest({
    required this.documentId,
    required this.warehouseId,
    required this.items,
    this.comment,
  });

  final String documentId;
  final String warehouseId;
  final String? comment;
  final List<CompleteInventoryItemRequest> items;

  @override
  List<Object?> get props => [documentId, warehouseId, comment, items];
}

class CompleteInventoryItemRequest extends Equatable {
  const CompleteInventoryItemRequest({
    required this.productId,
    required this.amount,
  });

  final String productId;
  final double amount;

  @override
  List<Object?> get props => [productId, amount];
}
