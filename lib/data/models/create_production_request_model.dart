import '../../domain/entities/create_production_request.dart';

extension CreateProductionRequestModel on CreateProductionRequest {
  Map<String, dynamic> to1CJson() => {
        'skladID': warehouseId,
        'comment': comment ?? '',
        'tovary': items.map((e) => e.to1CJson()).toList(),
      };
}

extension CreateProductionItemRequestModel on CreateProductionItemRequest {
  Map<String, dynamic> to1CJson() => {
        'tovarID': productId,
        'amount': amount,
      };
}
