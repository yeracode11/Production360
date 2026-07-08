import 'package:equatable/equatable.dart';

/// POST /mobile/spisaniyezapasov/create
class CreateWriteoffRequest extends Equatable {
  const CreateWriteoffRequest({
    required this.warehouseId,
    required this.reasonId,
    required this.items,
    this.comment,
  });

  final String warehouseId;

  /// Причина списания (`reasonID`) — из «ДоступныеПричины» predata.
  final String reasonId;
  final String? comment;
  final List<CreateWriteoffItemRequest> items;

  @override
  List<Object?> get props => [warehouseId, reasonId, comment, items];
}

class CreateWriteoffItemRequest extends Equatable {
  const CreateWriteoffItemRequest({
    required this.productId,
    required this.amount,
  });

  final String productId;
  final double amount;

  @override
  List<Object?> get props => [productId, amount];
}
