import 'package:equatable/equatable.dart';

/// Документ списания запасов из 1С.
class StockWriteoff extends Equatable {
  const StockWriteoff({
    required this.id,
    required this.number,
    required this.date,
    required this.isPosted,
    required this.organizationId,
    required this.organizationName,
    required this.warehouseId,
    required this.warehouseName,
    this.reasonId,
    this.reasonName,
    this.comment,
    this.dateDisplay,
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
  final String? reasonId;
  final String? reasonName;
  final String? comment;
  final String? dateDisplay;
  final List<StockWriteoffItem> items;

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
        reasonId,
        reasonName,
        comment,
        dateDisplay,
        items,
      ];
}

class StockWriteoffItem extends Equatable {
  const StockWriteoffItem({
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
