import 'package:equatable/equatable.dart';

/// POST /mobile/internaltransfer/create
class CreateTransferRequest extends Equatable {
  const CreateTransferRequest({
    required this.senderWarehouseId,
    required this.clientWarehouseId,
    required this.items,
    this.comment,
  });

  /// Склад-отправитель (`skladID`) — текущая точка пользователя.
  final String senderWarehouseId;

  /// Склад получателя (`skladClientID`) — из «ДоступныеСклады» predata.
  final String clientWarehouseId;
  final String? comment;
  final List<CreateTransferItemRequest> items;

  @override
  List<Object?> get props => [
        senderWarehouseId,
        clientWarehouseId,
        comment,
        items,
      ];
}

class CreateTransferItemRequest extends Equatable {
  const CreateTransferItemRequest({
    required this.productId,
    required this.amount,
  });

  final String productId;
  final double amount;

  @override
  List<Object?> get props => [productId, amount];
}
