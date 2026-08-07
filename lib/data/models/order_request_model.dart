import '../../core/utils/one_c_author.dart';
import '../../core/utils/one_c_bool.dart';
import '../../core/utils/one_c_date.dart';
import '../../domain/enums/order_status.dart';
import '../../domain/entities/order_request.dart';
import 'order_item_model.dart';
import 'order_receipt_item_model.dart';

class OrderRequestModel extends OrderRequest {
  const OrderRequestModel({
    required super.id,
    required super.orderNumber,
    required super.outletId,
    required super.customer,
    required super.supplier,
    required super.deliveryDate,
    required super.status,
    super.createdDate,
    super.orderType,
    super.orderTypeId,
    super.orderTypeForInfo = false,
    super.comment,
    super.statusLabel,
    super.organization,
    super.warehouseName,
    super.recipientOrganization,
    super.recipientWarehouse,
    super.author,
    super.authorLogin,
    super.createdDateDisplay,
    super.deliveryDateDisplay,
    super.items = const [],
    super.receiptItems = const [],
  });

  /// Parses list item from GET /mobile/zayavka?sklad= «Документы».
  factory OrderRequestModel.from1CListJson(
    Map<String, dynamic> json, {
    required String outletId,
  }) {
    final authorFields = OneCAuthorFields.parse(json);
    return OrderRequestModel(
      id: json['Ссылка'] as String,
      orderNumber: json['Номер'] as String,
      outletId: outletId,
      customer: json['Отправитель'] as String,
      supplier: json['Отправитель'] as String,
      deliveryDate: parseOneCDate(json['ДатаОтгрузки'] as String),
      createdDate: json['Дата'] != null
          ? parseOneCDate(json['Дата'] as String)
          : null,
      status: statusFrom1C(json['СтатусЗаказа'] as String),
      orderType: json['ВидЗаказа'] as String?,
      orderTypeForInfo: parseOneCBool(json['forInfo']),
      statusLabel: json['СтатусЗаказа'] as String?,
      author: authorFields.name,
      authorLogin: authorFields.login,
      createdDateDisplay: json['Дата'] != null
          ? (json['Дата'] as String).trim()
          : null,
      deliveryDateDisplay: _formatListShipmentDate(json['ДатаОтгрузки'] as String),
      items: const [],
    );
  }

  static String _formatListShipmentDate(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith(':00')) {
      return trimmed.substring(0, trimmed.length - 3);
    }
    return trimmed;
  }

  /// Parses detail from GET /mobile/zayavka?id= «data» object.
  factory OrderRequestModel.from1CDetailJson(Map<String, dynamic> json) {
    final productsJson = json['Товары'] as List<dynamic>? ?? [];
    final receiptJson = json['ТоварыПриемки'] as List<dynamic>? ?? [];
    final authorFields = OneCAuthorFields.parse(json);

    return OrderRequestModel(
      id: json['Ссылка'] as String,
      orderNumber: json['Номер'] as String,
      outletId: json['СкладПолучательСсылка'] as String,
      customer: json['ОрганизацияПолучатель'] as String,
      supplier: json['Организация'] as String,
      deliveryDate: parseOneCDate(json['ДатаОтгрузки'] as String),
      createdDate: json['Дата'] != null
          ? parseOneCDate(json['Дата'] as String)
          : null,
      status: statusFrom1C(json['СтатусЗаказа'] as String),
      orderType: json['ВидЗаказа'] as String?,
      orderTypeId: json['ВидЗаказаСсылка'] as String?,
      orderTypeForInfo: parseOneCBool(json['forInfo']),
      comment: _nullableString(json['Комментарий']),
      statusLabel: json['СтатусЗаказа'] as String?,
      organization: json['Организация'] as String?,
      warehouseName: json['Склад'] as String?,
      recipientOrganization: json['ОрганизацияПолучатель'] as String?,
      recipientWarehouse: json['СкладПолучатель'] as String?,
      author: authorFields.name,
      authorLogin: authorFields.login,
      createdDateDisplay: json['ДатаПредставление'] as String?,
      deliveryDateDisplay: json['ДатаОтгрузкиПредставление'] as String?,
      items: productsJson
          .map((e) => OrderItemModel.from1CProductJson(e as Map<String, dynamic>))
          .toList(),
      receiptItems: receiptJson
          .map((e) => OrderReceiptItemModel.from1CJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  factory OrderRequestModel.fromJson(Map<String, dynamic> json) {
    return OrderRequestModel(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      outletId: json['outletId'] as String,
      customer: json['customer'] as String,
      supplier: json['supplier'] as String,
      deliveryDate: DateTime.parse(json['deliveryDate'] as String),
      status: _statusFromString(json['status'] as String),
      orderType: json['orderType'] as String?,
      orderTypeId: json['orderTypeId'] as String?,
      comment: json['comment'] as String?,
      statusLabel: json['statusLabel'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static OrderStatus statusFrom1C(String value) {
    switch (value.trim()) {
      case 'Создан':
        return OrderStatus.pendingConfirmation;
      case 'Отгружен':
        return OrderStatus.pendingDelivery;
      case 'Получен':
        return OrderStatus.completed;
      default:
        return OrderStatus.pendingConfirmation;
    }
  }

  static OrderStatus _statusFromString(String value) {
    switch (value) {
      case 'pending_confirmation':
        return OrderStatus.pendingConfirmation;
      case 'pending_delivery':
        return OrderStatus.pendingDelivery;
      case 'completed':
        return OrderStatus.completed;
      default:
        return OrderStatus.pendingConfirmation;
    }
  }

  static String statusToString(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingConfirmation:
        return 'pending_confirmation';
      case OrderStatus.pendingDelivery:
        return 'pending_delivery';
      case OrderStatus.completed:
        return 'completed';
    }
  }

  OrderRequestModel copyWith({String? comment}) {
    return OrderRequestModel(
      id: id,
      orderNumber: orderNumber,
      outletId: outletId,
      customer: customer,
      supplier: supplier,
      deliveryDate: deliveryDate,
      createdDate: createdDate,
      status: status,
      orderType: orderType,
      orderTypeId: orderTypeId,
      orderTypeForInfo: orderTypeForInfo,
      comment: comment ?? this.comment,
      statusLabel: statusLabel,
      organization: organization,
      warehouseName: warehouseName,
      recipientOrganization: recipientOrganization,
      recipientWarehouse: recipientWarehouse,
      author: author,
      authorLogin: authorLogin,
      createdDateDisplay: createdDateDisplay,
      deliveryDateDisplay: deliveryDateDisplay,
      items: items,
      receiptItems: receiptItems,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderNumber': orderNumber,
        'outletId': outletId,
        'customer': customer,
        'supplier': supplier,
        'deliveryDate': deliveryDate.toIso8601String(),
        'status': statusToString(status),
        'orderType': orderType,
        'orderTypeId': orderTypeId,
        'comment': comment,
        'statusLabel': statusLabel,
        'items': items.map((e) => (e as OrderItemModel).toJson()).toList(),
      };
}
