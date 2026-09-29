import '../../domain/entities/create_return_request.dart';

extension CreateReturnRequestModel on CreateReturnRequest {
  Map<String, dynamic> to1CJson() => {
        'skladID': warehouseId,
        'docIDOsnovanie': incomingInvoiceId,
        'comment': comment ?? '',
        'tovary': items.map((e) => e.to1CJson()).toList(),
      };
}

extension CreateReturnItemRequestModel on CreateReturnItemRequest {
  Map<String, dynamic> to1CJson() {
    final value = quantity;
    return {
      'tovarID': productId,
      'edIzmID': unitId,
      'amount': value == value.roundToDouble() ? value.round() : value,
      'price': price,
    };
  }
}
