import 'package:equatable/equatable.dart';

class ReturnPredata extends Equatable {
  const ReturnPredata({
    required this.organizationId,
    required this.organizationName,
    required this.incomingInvoices,
  });

  final String organizationId;
  final String organizationName;
  final List<IncomingInvoiceSummary> incomingInvoices;

  /// «Склад(Организация)» получателя — текущая точка.
  String recipientWarehouseDisplay(String warehouseName) {
    final warehouse = warehouseName.trim();
    final organization = organizationName.trim();
    if (warehouse.isEmpty) return organization;
    if (organization.isEmpty) return warehouse;
    return '$warehouse($organization)';
  }

  @override
  List<Object?> get props => [organizationId, organizationName, incomingInvoices];
}

class IncomingInvoiceSummary extends Equatable {
  const IncomingInvoiceSummary({
    required this.id,
    required this.date,
    required this.number,
    required this.senderOrganizationName,
    required this.senderWarehouseName,
    required this.productsText,
  });

  final String id;
  final String date;
  final String number;
  final String senderOrganizationName;
  final String senderWarehouseName;
  final String productsText;

  /// «Склад(Организация)» отправителя.
  String get senderWarehouseDisplay {
    final warehouse = senderWarehouseName.trim();
    final organization = senderOrganizationName.trim();
    if (warehouse.isEmpty) return organization;
    if (organization.isEmpty) return warehouse;
    return '$warehouse($organization)';
  }

  bool matchesSearchQuery(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;

    final haystack = [
      number,
      date,
      senderWarehouseName,
      senderOrganizationName,
      senderWarehouseDisplay,
      productsText,
    ].join(' ').toLowerCase();

    return haystack.contains(normalizedQuery);
  }

  @override
  List<Object?> get props => [
        id,
        date,
        number,
        senderOrganizationName,
        senderWarehouseName,
        productsText,
      ];
}
