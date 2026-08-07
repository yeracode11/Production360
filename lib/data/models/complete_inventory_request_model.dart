import '../../domain/entities/complete_inventory_request.dart';

extension CompleteInventoryRequestModel on CompleteInventoryRequest {
  Map<String, dynamic> to1CJson() => {
        'docID': documentId,
        'skladID': warehouseId,
        'comment': comment ?? '',
        'tovary': items.map((e) => e.to1CJson()).toList(),
      };
}

extension CompleteInventoryItemRequestModel on CompleteInventoryItemRequest {
  Map<String, dynamic> to1CJson() {
    final value = amount;
    return {
      'tovarID': productId,
      'amount': value == value.roundToDouble() ? value.round() : value,
    };
  }
}
