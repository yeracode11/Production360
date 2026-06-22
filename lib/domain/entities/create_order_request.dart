import 'package:equatable/equatable.dart';

/// Payload for POST /mobile/zayavka.
class CreateOrderRequest extends Equatable {
  const CreateOrderRequest({
    required this.skladClientId,
    required this.organizationId,
    required this.skladId,
    required this.orderTypeId,
    required this.date,
    required this.items,
    this.comment,
  });

  final String skladClientId;
  final String organizationId;
  final String skladId;
  final String orderTypeId;
  final String date;
  final String? comment;
  final List<CreateOrderItemRequest> items;

  @override
  List<Object?> get props => [
        skladClientId,
        organizationId,
        skladId,
        orderTypeId,
        date,
        comment,
        items,
      ];
}

class CreateOrderItemRequest extends Equatable {
  const CreateOrderItemRequest({
    required this.productId,
    required this.amount,
  });

  final String productId;
  final String amount;

  @override
  List<Object?> get props => [productId, amount];
}
