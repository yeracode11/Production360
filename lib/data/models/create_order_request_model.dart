import '../../domain/entities/create_order_request.dart';

extension CreateOrderRequestModel on CreateOrderRequest {
  Map<String, dynamic> to1CJson() => {
        'skladClientID': skladClientId,
        'organizationID': organizationId,
        'skladID': skladId,
        'idType': orderTypeId,
        'date': date,
        'comment': comment ?? '',
        'tovary': items.map((e) => e.to1CJson()).toList(),
      };
}

extension CreateOrderItemRequestModel on CreateOrderItemRequest {
  Map<String, dynamic> to1CJson() => {
        'id': productId,
        'amount': amount,
      };
}
