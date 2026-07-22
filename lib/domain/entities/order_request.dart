import 'package:equatable/equatable.dart';

import '../enums/order_status.dart';
import 'order_item.dart';
import 'order_receipt_item.dart';

/// Procurement order request with full detail fields.
class OrderRequest extends Equatable {
  const OrderRequest({
    required this.id,
    required this.orderNumber,
    required this.outletId,
    required this.customer,
    required this.supplier,
    required this.deliveryDate,
    required this.status,
    this.createdDate,
    this.orderType,
    this.orderTypeId,
    this.orderTypeForInfo = false,
    this.comment,
    this.statusLabel,
    this.organization,
    this.warehouseName,
    this.recipientOrganization,
    this.recipientWarehouse,
    this.author,
    this.authorLogin,
    this.createdDateDisplay,
    this.deliveryDateDisplay,
    this.items = const [],
    this.receiptItems = const [],
  });

  final String id;
  final String orderNumber;
  final String outletId;
  final String customer;
  final String supplier;
  final DateTime deliveryDate;
  /// Дата создания заявки из 1С «Дата».
  final DateTime? createdDate;
  final String? orderType;
  final String? orderTypeId;
  /// Сопутствующий товар (`forInfo` из 1С).
  final bool orderTypeForInfo;
  final String? comment;
  /// Raw status label from 1C «СтатусЗаказа», e.g. «Создан», «Получен».
  final String? statusLabel;
  final String? organization;
  final String? warehouseName;
  final String? recipientOrganization;
  final String? recipientWarehouse;
  final String? author;
  final String? authorLogin;
  final String? createdDateDisplay;
  final String? deliveryDateDisplay;
  final OrderStatus status;
  final List<OrderItem> items;
  final List<OrderReceiptItem> receiptItems;

  bool get isCompleted => status == OrderStatus.completed;

  String get displayStatus => statusLabel ?? status.label;

  /// Receipt acceptance is only available for shipped orders («Отгружен»).
  bool get canEditReceipt => status == OrderStatus.pendingDelivery;

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        outletId,
        customer,
        supplier,
        deliveryDate,
        createdDate,
        orderType,
        orderTypeId,
        orderTypeForInfo,
        comment,
        statusLabel,
        organization,
        warehouseName,
        recipientOrganization,
        recipientWarehouse,
        author,
        authorLogin,
        createdDateDisplay,
        deliveryDateDisplay,
        status,
        items,
        receiptItems,
      ];
}
