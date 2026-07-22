import 'package:equatable/equatable.dart';

/// Документ инвентаризации из 1С.
class InventoryDocument extends Equatable {
  const InventoryDocument({
    required this.id,
    required this.number,
    required this.date,
    required this.isPosted,
    required this.organizationId,
    required this.organizationName,
    required this.warehouseId,
    required this.warehouseName,
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
  final String warehouseId;
  final String warehouseName;
  final String? comment;
  final String? dateDisplay;
  final String? author;
  final String? authorLogin;
  final List<InventoryDocumentItem> items;

  @override
  List<Object?> get props => [
        id,
        number,
        date,
        isPosted,
        organizationId,
        organizationName,
        warehouseId,
        warehouseName,
        comment,
        dateDisplay,
        author,
        authorLogin,
        items,
      ];
}

class InventoryDocumentItem extends Equatable {
  const InventoryDocumentItem({
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
