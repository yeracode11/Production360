import '../../domain/entities/create_transfer_request.dart';

extension CreateTransferRequestModel on CreateTransferRequest {
  Map<String, dynamic> to1CJson() => {
        'skladID': senderWarehouseId,
        'skladClientID': clientWarehouseId,
        'comment': comment ?? '',
        'tovary': items.map((e) => e.to1CJson()).toList(),
      };
}

extension CreateTransferItemRequestModel on CreateTransferItemRequest {
  Map<String, dynamic> to1CJson() => {
        'tovarID': productId,
        'amount': amount,
      };
}
