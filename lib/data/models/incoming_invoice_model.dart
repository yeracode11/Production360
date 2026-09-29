import '../../core/utils/one_c_date.dart';
import '../../domain/entities/incoming_invoice.dart';

class IncomingInvoiceModel extends IncomingInvoice {
  const IncomingInvoiceModel({
    required super.id,
    required super.number,
    required super.date,
    required super.isPosted,
    required super.organizationId,
    required super.organizationName,
    required super.warehouseId,
    required super.warehouseName,
    required super.senderOrganizationId,
    required super.senderOrganizationName,
    required super.senderWarehouseId,
    required super.senderWarehouseName,
    super.operationType,
    super.documentSum,
    super.comment,
    super.dateDisplay,
    super.items = const [],
  });

  factory IncomingInvoiceModel.from1CDetailJson(Map<String, dynamic> json) {
    final itemsJson = json['Товары'] as List<dynamic>? ?? [];
    final dateRaw = json['Дата'] as String?;

    return IncomingInvoiceModel(
      id: json['Ссылка'] as String,
      number: json['Номер'] as String,
      date: dateRaw != null ? parseOneCDate(dateRaw) : DateTime.now(),
      dateDisplay: dateRaw,
      isPosted: json['Проведен'] as bool? ?? false,
      organizationId: _firstNonEmptyString(json, [
        'ОрганизацияСсылка',
        'ОрганизацияПолучательСсылка',
      ]),
      organizationName: _firstNonEmptyString(json, [
        'ОрганизацияНаименование',
        'Организация',
        'ОрганизацияПолучательНаименование',
      ]),
      warehouseId: _firstNonEmptyString(json, [
        'СкладСсылка',
        'СкладПолучательСсылка',
      ]),
      warehouseName: _firstNonEmptyString(json, [
        'СкладНаименование',
        'Склад',
        'СкладПолучательНаименование',
      ]),
      senderOrganizationId: json['ОрганизацияОтправительСсылка'] as String? ?? '',
      senderOrganizationName:
          json['ОрганизацияОтправительНаименование'] as String? ?? '',
      senderWarehouseId: json['СкладОтправительСсылка'] as String? ?? '',
      senderWarehouseName: json['СкладОтправительНаименование'] as String? ?? '',
      operationType: _nullableString(json['ВидОперации']),
      documentSum: _nullableDouble(json['СуммаДокумента']),
      comment: _nullableString(json['Комментарий']),
      items: itemsJson
          .map(
            (e) => IncomingInvoiceItemModel.from1CJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static double? _nullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static String _firstNonEmptyString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  IncomingInvoiceModel copyWith({
    String? organizationName,
    String? warehouseName,
  }) {
    return IncomingInvoiceModel(
      id: id,
      number: number,
      date: date,
      isPosted: isPosted,
      organizationId: organizationId,
      organizationName: organizationName ?? this.organizationName,
      warehouseId: warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      senderOrganizationId: senderOrganizationId,
      senderOrganizationName: senderOrganizationName,
      senderWarehouseId: senderWarehouseId,
      senderWarehouseName: senderWarehouseName,
      operationType: operationType,
      documentSum: documentSum,
      comment: comment,
      dateDisplay: dateDisplay,
      items: items,
    );
  }
}

class IncomingInvoiceItemModel extends IncomingInvoiceItem {
  const IncomingInvoiceItemModel({
    required super.productId,
    required super.name,
    required super.quantity,
    super.code,
    super.unit,
    super.unitId,
    super.price,
    super.sum,
  });

  factory IncomingInvoiceItemModel.from1CJson(Map<String, dynamic> json) {
    return IncomingInvoiceItemModel(
      productId: json['НоменклатураСсылка'] as String,
      name: json['НоменклатураНаименование'] as String,
      quantity: (json['Количество'] as num).toDouble(),
      code: json['НоменклатураКод'] as String?,
      unit: json['ЕдиницаИзмерения'] as String?,
      unitId: json['ЕдиницаИзмеренияСсылка'] as String? ??
          json['edIzmID'] as String?,
      price: IncomingInvoiceModel._nullableDouble(json['Цена']),
      sum: IncomingInvoiceModel._nullableDouble(json['Сумма']),
    );
  }
}
