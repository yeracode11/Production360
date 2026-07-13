import '../../domain/entities/create_inventory_request.dart';

extension CreateInventoryRequestModel on CreateInventoryRequest {
  Map<String, dynamic> to1CJson() => {
        'skladID': warehouseId,
        'comment': comment ?? '',
        'tovary': items.map((e) => e.to1CJson()).toList(),
      };
}

extension CreateInventoryItemRequestModel on CreateInventoryItemRequest {
  Map<String, dynamic> to1CJson() => {
        'tovarID': productId,
        'amount': amount,
      };
}
