import '../../domain/entities/create_production_request.dart';

extension CreateProductionRequestModel on CreateProductionRequest {
  Map<String, dynamic> to1CJson() => {
        'skladProdID': productsWarehouseId,
        'skladSyriaID': rawMaterialsWarehouseId,
        'comment': comment ?? '',
        'tovary': items.map((e) => e.to1CJson()).toList(),
      };
}

extension CreateProductionItemRequestModel on CreateProductionItemRequest {
  Map<String, dynamic> to1CJson() {
    final value = amount;
    return {
      'tovarID': productId,
      'amount': value == value.roundToDouble() ? value.round() : value,
    };
  }
}
