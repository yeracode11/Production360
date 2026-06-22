import '../../domain/entities/receipt_order_request.dart';

extension ReceiptOrderRequestJson on ReceiptOrderRequest {
  Map<String, dynamic> to1CJson() => {
        'id': orderId,
        'tovary': items.map((e) => e.to1CJson()).toList(),
      };
}

extension ReceiptOrderItemRequestJson on ReceiptOrderItemRequest {
  Map<String, dynamic> to1CJson() => {
        'id': productId,
        'shipped': shipped,
        'received': received,
      };
}
