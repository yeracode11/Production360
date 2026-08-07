import 'package:equatable/equatable.dart';

/// POST /mobile/proizvodstvo/create
class CreateProductionRequest extends Equatable {
  const CreateProductionRequest({
    required this.productsWarehouseId,
    required this.rawMaterialsWarehouseId,
    required this.items,
    this.comment,
  });

  /// Склад продукции (`skladProdID`).
  final String productsWarehouseId;

  /// Склад сырья (`skladSyriaID`).
  final String rawMaterialsWarehouseId;
  final String? comment;
  final List<CreateProductionItemRequest> items;

  @override
  List<Object?> get props => [
        productsWarehouseId,
        rawMaterialsWarehouseId,
        comment,
        items,
      ];
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
