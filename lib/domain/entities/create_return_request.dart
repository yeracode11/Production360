import 'package:equatable/equatable.dart';

/// POST /mobile/vozvrat/create — создать возврат поставщику.
class CreateReturnRequest extends Equatable {
  const CreateReturnRequest({
    required this.warehouseId,
    required this.incomingInvoiceId,
    required this.items,
    this.comment,
  });

  final String warehouseId;
  final String incomingInvoiceId;
  final String? comment;
  final List<CreateReturnItemRequest> items;

  @override
  List<Object?> get props => [
        warehouseId,
        incomingInvoiceId,
        comment,
        items,
      ];
}

class CreateReturnItemRequest extends Equatable {
  const CreateReturnItemRequest({
    required this.productId,
    required this.unitId,
    required this.quantity,
    required this.price,
  });

  final String productId;
  final String unitId;
  final double quantity;
  final double price;

  @override
  List<Object?> get props => [productId, unitId, quantity, price];
}
