import 'package:equatable/equatable.dart';

/// Документ возврата поставщику из 1С.
class ReturnDocument extends Equatable {
  const ReturnDocument({
    required this.id,
    required this.number,
    required this.date,
    required this.isPosted,
    required this.senderWarehouseId,
    required this.senderWarehouseName,
    required this.senderOrganizationId,
    required this.senderOrganizationName,
    required this.recipientOrganizationId,
    required this.recipientOrganizationName,
    required this.recipientWarehouseId,
    required this.recipientWarehouseName,
    this.operationType,
    this.documentSum,
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
  final String senderWarehouseId;
  final String senderWarehouseName;
  final String senderOrganizationId;
  final String senderOrganizationName;
  final String recipientOrganizationId;
  final String recipientOrganizationName;
  final String recipientWarehouseId;
  final String recipientWarehouseName;
  final String? operationType;
  final double? documentSum;
  final String? comment;
  final String? dateDisplay;
  final String? author;
  final String? authorLogin;
  final List<ReturnDocumentItem> items;

  /// «Склад(Организация)» получателя.
  String get recipientWarehouseDisplay =>
      _warehouseWithOrganization(
        recipientWarehouseName,
        recipientOrganizationName,
      );

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
        senderWarehouseId,
        senderWarehouseName,
        senderOrganizationId,
        senderOrganizationName,
        recipientOrganizationId,
        recipientOrganizationName,
        recipientWarehouseId,
        recipientWarehouseName,
        operationType,
        documentSum,
        comment,
        dateDisplay,
        author,
        authorLogin,
        items,
      ];
}

class ReturnDocumentItem extends Equatable {
  const ReturnDocumentItem({
    required this.productId,
    required this.name,
    required this.quantity,
    this.code,
    this.unit,
    this.price,
    this.sum,
  });

  final String productId;
  final String name;
  final double quantity;
  final String? code;
  final String? unit;
  final double? price;
  final double? sum;

  @override
  List<Object?> get props => [productId, name, quantity, code, unit, price, sum];
}
