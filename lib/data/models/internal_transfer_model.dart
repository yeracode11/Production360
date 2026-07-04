import '../../core/utils/one_c_date.dart';
import '../../domain/entities/internal_transfer.dart';

class InternalTransferModel extends InternalTransfer {
  const InternalTransferModel({
    required super.id,
    required super.number,
    required super.date,
    required super.isPosted,
    required super.organizationId,
    required super.organizationName,
    required super.senderWarehouseId,
    required super.senderWarehouseName,
    required super.recipientWarehouseId,
    required super.recipientWarehouseName,
    super.comment,
    super.dateDisplay,
    super.items = const [],
  });

  /// GET /mobile/internaltransfer?skladID=&date= → элемент «data».
  factory InternalTransferModel.from1CListJson(Map<String, dynamic> json) {
    final dateRaw = json['Дата'] as String;
    return InternalTransferModel(
      id: json['Ссылка'] as String,
      number: json['Номер'] as String,
      date: parseOneCDate(dateRaw),
      dateDisplay: dateRaw,
      isPosted: json['Проведен'] as bool? ?? false,
      organizationId: json['ОрганизацияСсылка'] as String,
      organizationName: json['ОрганизацияНаименование'] as String,
      senderWarehouseId: json['СкладОтправительСсылка'] as String,
      senderWarehouseName: json['СкладОтправительНаименование'] as String,
      recipientWarehouseId: json['СкладПолучательСсылка'] as String,
      recipientWarehouseName: json['СкладПолучательНаименование'] as String,
      comment: _nullableString(json['Комментарий']),
    );
  }

  /// GET /mobile/internaltransfer?docID= → «data».
  factory InternalTransferModel.from1CDetailJson(Map<String, dynamic> json) {
    final itemsJson = json['Товары'] as List<dynamic>? ?? [];
    final dateRaw = json['Дата'] as String?;

    return InternalTransferModel(
      id: json['Ссылка'] as String,
      number: json['Номер'] as String,
      date: dateRaw != null ? parseOneCDate(dateRaw) : DateTime.now(),
      dateDisplay: dateRaw,
      isPosted: json['Проведен'] as bool? ?? false,
      organizationId: json['ОрганизацияСсылка'] as String? ?? '',
      organizationName: json['ОрганизацияНаименование'] as String? ?? '',
      senderWarehouseId: json['СкладОтправительСсылка'] as String? ?? '',
      senderWarehouseName: json['СкладОтправительНаименование'] as String? ?? '',
      recipientWarehouseId: json['СкладПолучательСсылка'] as String? ?? '',
      recipientWarehouseName:
          json['СкладПолучательНаименование'] as String? ?? '',
      comment: _nullableString(json['Комментарий']),
      items: itemsJson
          .map(
            (e) => InternalTransferItemModel.from1CJson(
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
}

class InternalTransferItemModel extends InternalTransferItem {
  const InternalTransferItemModel({
    required super.productId,
    required super.name,
    required super.quantity,
    super.code,
    super.unit,
  });

  factory InternalTransferItemModel.from1CJson(Map<String, dynamic> json) {
    return InternalTransferItemModel(
      productId: json['НоменклатураСсылка'] as String,
      name: json['НоменклатураНаименование'] as String,
      quantity: (json['Количество'] as num).toDouble(),
      code: json['НоменклатураКод'] as String?,
      unit: json['ЕдиницаИзмерения'] as String?,
    );
  }
}
