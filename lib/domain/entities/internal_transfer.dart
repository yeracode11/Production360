import 'package:equatable/equatable.dart';

/// Документ внутреннего перемещения из 1С (список / деталь).
class InternalTransfer extends Equatable {
  const InternalTransfer({
    required this.id,
    required this.number,
    required this.date,
    required this.isPosted,
    required this.organizationId,
    required this.organizationName,
    required this.senderWarehouseId,
    required this.senderWarehouseName,
    required this.recipientWarehouseId,
    required this.recipientWarehouseName,
    this.comment,
    this.dateDisplay,
    this.author,
    this.authorLogin,
    this.items = const [],
  });

  final String id;
  final String number;
  final DateTime date;
  final bool isPosted;
  final String organizationId;
  final String organizationName;
  final String senderWarehouseId;
  final String senderWarehouseName;
  final String recipientWarehouseId;
  final String recipientWarehouseName;
  final String? comment;
  /// «11.06.2026 22:50:02» из 1С.
  final String? dateDisplay;
  final String? author;
  final String? authorLogin;
  final List<InternalTransferItem> items;

  @override
  List<Object?> get props => [
        id,
        number,
        date,
        isPosted,
        organizationId,
        organizationName,
        senderWarehouseId,
        senderWarehouseName,
        recipientWarehouseId,
        recipientWarehouseName,
        comment,
        dateDisplay,
        author,
        authorLogin,
        items,
      ];
}

/// Строка товара в документе перемещения.
class InternalTransferItem extends Equatable {
  const InternalTransferItem({
    required this.productId,
    required this.name,
    required this.quantity,
    this.code,
    this.unit,
  });

  final String productId;
  final String name;
  final double quantity;
  final String? code;
  final String? unit;

  @override
  List<Object?> get props => [productId, name, quantity, code, unit];
}
