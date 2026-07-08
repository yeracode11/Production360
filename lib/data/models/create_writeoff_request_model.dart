import '../../domain/entities/create_writeoff_request.dart';

extension CreateWriteoffRequestModel on CreateWriteoffRequest {
  Map<String, dynamic> to1CJson() => {
        'skladID': warehouseId,
        'reasonID': reasonId,
        'comment': comment ?? '',
        'tovary': items.map((e) => e.to1CJson()).toList(),
      };
}

extension CreateWriteoffItemRequestModel on CreateWriteoffItemRequest {
  Map<String, dynamic> to1CJson() => {
        'tovarID': productId,
        'amount': amount,
      };
}
