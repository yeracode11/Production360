import 'package:equatable/equatable.dart';

/// POST /mobile/invent/create
class CreateInventoryRequest extends Equatable {
  const CreateInventoryRequest({
    required this.warehouseId,
    required this.items,
    this.comment,
  });

  final String warehouseId;
  final String? comment;
  final List<CreateInventoryItemRequest> items;

  @override
  List<Object?> get props => [warehouseId, comment, items];
}

class CreateInventoryItemRequest extends Equatable {
  const CreateInventoryItemRequest({
    required this.productId,
    required this.amount,
  });

  final String productId;
  final double amount;

  @override
  List<Object?> get props => [productId, amount];
}
