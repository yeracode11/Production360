import 'package:equatable/equatable.dart';

/// Документ производства из 1С.
class ProductionDocument extends Equatable {
  const ProductionDocument({
    required this.id,
    required this.number,
    required this.date,
    required this.isPosted,
    required this.organizationId,
    required this.organizationName,
    required this.warehouseId,
    required this.warehouseName,
    this.rawMaterialsWarehouseName,
    this.departmentName,
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
  final String? rawMaterialsWarehouseName;
  final String? departmentName;
  final String? comment;
  final String? dateDisplay;
  final String? author;
  final String? authorLogin;
  final List<ProductionDocumentItem> items;

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
        rawMaterialsWarehouseName,
        departmentName,
        comment,
        dateDisplay,
        author,
        authorLogin,
        items,
      ];
}

class ProductionDocumentItem extends Equatable {
  const ProductionDocumentItem({
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
