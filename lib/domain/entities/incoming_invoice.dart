import 'package:equatable/equatable.dart';

/// Приходная накладная из 1С.
class IncomingInvoice extends Equatable {
  const IncomingInvoice({
    required this.id,
    required this.number,
    required this.date,
    required this.isPosted,
    required this.organizationId,
    required this.organizationName,
    required this.warehouseId,
    required this.warehouseName,
    required this.senderOrganizationId,
    required this.senderOrganizationName,
    required this.senderWarehouseId,
    required this.senderWarehouseName,
    this.operationType,
    this.documentSum,
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
  final String senderOrganizationId;
  final String senderOrganizationName;
  final String senderWarehouseId;
  final String senderWarehouseName;
  final String? operationType;
  final double? documentSum;
  final String? comment;
  final String? dateDisplay;
  final List<IncomingInvoiceItem> items;

  /// «Склад(Организация)» получателя.
  String get recipientWarehouseDisplay =>
      _warehouseWithOrganization(warehouseName, organizationName);

  /// «Склад(Организация)» отправителя.
  String get senderWarehouseDisplay => _warehouseWithOrganization(
        senderWarehouseName,
        senderOrganizationName,
      );

  static String _warehouseWithOrganization(
    String warehouseName,
    String organizationName,
  ) {
    final warehouse = warehouseName.trim();
    final organization = organizationName.trim();
    if (warehouse.isEmpty) return organization;
    if (organization.isEmpty) return warehouse;
    return '$warehouse($organization)';
  }

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
        senderOrganizationId,
        senderOrganizationName,
        senderWarehouseId,
        senderWarehouseName,
        operationType,
        documentSum,
        comment,
        dateDisplay,
        items,
      ];
}

class IncomingInvoiceItem extends Equatable {
  const IncomingInvoiceItem({
    required this.productId,
    required this.name,
    required this.quantity,
    this.code,
    this.unit,
    this.unitId,
    this.price,
    this.sum,
  });

  final String productId;
  final String name;
  final double quantity;
  final String? code;
  final String? unit;
  final String? unitId;
  final double? price;
  final double? sum;

  @override
  List<Object?> get props =>
      [productId, name, quantity, code, unit, unitId, price, sum];
}
