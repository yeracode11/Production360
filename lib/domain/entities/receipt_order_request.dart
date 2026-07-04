import 'package:equatable/equatable.dart';

/// Payload for PATCH /mobile/zayavka (приёмка).
class ReceiptOrderRequest extends Equatable {
  const ReceiptOrderRequest({
    required this.orderId,
    required this.items,
  });

  final String orderId;
  final List<ReceiptOrderItemRequest> items;

  @override
  List<Object?> get props => [orderId, items];
}

class ReceiptOrderItemRequest extends Equatable {
  const ReceiptOrderItemRequest({
    required this.productId,
    required this.shipped,
    required this.received,
  });

  final String productId;
  final int shipped;
  final String received;

  @override
  List<Object?> get props => [productId, shipped, received];
}
