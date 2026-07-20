import 'package:equatable/equatable.dart';

/// POST /mobile/proizvodstvo/create
class CreateProductionRequest extends Equatable {
  const CreateProductionRequest({
    required this.warehouseId,
    required this.items,
    this.comment,
  });

  final String warehouseId;
  final String? comment;
  final List<CreateProductionItemRequest> items;

  @override
  List<Object?> get props => [warehouseId, comment, items];
}

class CreateProductionItemRequest extends Equatable {
  const CreateProductionItemRequest({
    required this.productId,
    required this.amount,
  });

  final String productId;
  final double amount;

  @override
  List<Object?> get props => [productId, amount];
}
