import '../../core/utils/one_c_author.dart';
import '../../core/utils/one_c_date.dart';
import '../../domain/entities/return_document.dart';

class ReturnDocumentModel extends ReturnDocument {
  const ReturnDocumentModel({
    required super.id,
    required super.number,
    required super.date,
    required super.isPosted,
    required super.senderWarehouseId,
    required super.senderWarehouseName,
    required super.senderOrganizationId,
    required super.senderOrganizationName,
    required super.recipientOrganizationId,
    required super.recipientOrganizationName,
    required super.recipientWarehouseId,
    required super.recipientWarehouseName,
    super.operationType,
    super.documentSum,
    super.comment,
    super.dateDisplay,
    super.author,
    super.authorLogin,
    super.items = const [],
  });

  factory ReturnDocumentModel.from1CListJson(Map<String, dynamic> json) {
    final dateRaw = json['Дата'] as String;
    final authorFields = OneCAuthorFields.parse(json);
    return ReturnDocumentModel(
      id: json['Ссылка'] as String,
      number: json['Номер'] as String,
      date: parseOneCDate(dateRaw),
      dateDisplay: dateRaw,
      isPosted: json['Проведен'] as bool? ?? false,
      senderWarehouseId: json['СкладОтправительСсылка'] as String? ?? '',
      senderWarehouseName: json['СкладОтправительНаименование'] as String? ?? '',
      senderOrganizationId: _firstNonEmptyString(json, [
        'ОрганизацияСсылка',
        'ОрганизацияОтправительСсылка',
      ]),
      senderOrganizationName: _firstNonEmptyString(json, [
        'ОрганизацияНаименование',
        'Организация',
        'ОрганизацияОтправительНаименование',
      ]),
      recipientOrganizationId:
          json['ОрганизацияПолучательСсылка'] as String? ?? '',
      recipientOrganizationName:
          json['ОрганизацияПолучательНаименование'] as String? ?? '',
      recipientWarehouseId: json['СкладПолучательСсылка'] as String? ?? '',
      recipientWarehouseName:
          json['СкладПолучательНаименование'] as String? ?? '',
      operationType: _nullableString(json['ВидОперации']),
      documentSum: _nullableDouble(json['СуммаДокумента']),
      comment: _nullableString(json['Комментарий']),
      author: authorFields.name,
      authorLogin: authorFields.login,
    );
  }

  factory ReturnDocumentModel.from1CDetailJson(Map<String, dynamic> json) {
    final itemsJson = json['Товары'] as List<dynamic>? ?? [];
    final dateRaw = json['Дата'] as String?;
    final authorFields = OneCAuthorFields.parse(json);

    return ReturnDocumentModel(
      id: json['Ссылка'] as String,
      number: json['Номер'] as String,
      date: dateRaw != null ? parseOneCDate(dateRaw) : DateTime.now(),
      dateDisplay: dateRaw,
      isPosted: json['Проведен'] as bool? ?? false,
      senderWarehouseId: json['СкладОтправительСсылка'] as String? ?? '',
      senderWarehouseName: json['СкладОтправительНаименование'] as String? ?? '',
      senderOrganizationId: _firstNonEmptyString(json, [
        'ОрганизацияСсылка',
        'ОрганизацияОтправительСсылка',
      ]),
      senderOrganizationName: _firstNonEmptyString(json, [
        'ОрганизацияНаименование',
        'Организация',
        'ОрганизацияОтправительНаименование',
      ]),
      recipientOrganizationId:
          json['ОрганизацияПолучательСсылка'] as String? ?? '',
      recipientOrganizationName:
          json['ОрганизацияПолучательНаименование'] as String? ?? '',
      recipientWarehouseId: json['СкладПолучательСсылка'] as String? ?? '',
      recipientWarehouseName:
          json['СкладПолучательНаименование'] as String? ?? '',
      operationType: _nullableString(json['ВидОперации']),
      documentSum: _nullableDouble(json['СуммаДокумента']),
      comment: _nullableString(json['Комментарий']),
      author: authorFields.name,
      authorLogin: authorFields.login,
      items: itemsJson
          .map(
            (e) => ReturnDocumentItemModel.from1CJson(
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

  static double? _nullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  ReturnDocumentModel copyWith({String? senderOrganizationName}) {
    return ReturnDocumentModel(
      id: id,
      number: number,
      date: date,
      isPosted: isPosted,
      senderWarehouseId: senderWarehouseId,
      senderWarehouseName: senderWarehouseName,
      senderOrganizationId: senderOrganizationId,
      senderOrganizationName:
          senderOrganizationName ?? this.senderOrganizationName,
      recipientOrganizationId: recipientOrganizationId,
      recipientOrganizationName: recipientOrganizationName,
      recipientWarehouseId: recipientWarehouseId,
      recipientWarehouseName: recipientWarehouseName,
      operationType: operationType,
      documentSum: documentSum,
      comment: comment,
      dateDisplay: dateDisplay,
      author: author,
      authorLogin: authorLogin,
      items: items,
    );
  }
}

class ReturnDocumentItemModel extends ReturnDocumentItem {
  const ReturnDocumentItemModel({
    required super.productId,
    required super.name,
    required super.quantity,
    super.code,
    super.unit,
    super.price,
    super.sum,
  });

  factory ReturnDocumentItemModel.from1CJson(Map<String, dynamic> json) {
    return ReturnDocumentItemModel(
      productId: json['НоменклатураСсылка'] as String,
      name: json['НоменклатураНаименование'] as String,
      quantity: (json['Количество'] as num).toDouble(),
      code: json['НоменклатураКод'] as String?,
      unit: json['ЕдиницаИзмерения'] as String?,
      price: ReturnDocumentModel._nullableDouble(json['Цена']),
      sum: ReturnDocumentModel._nullableDouble(json['Сумма']),
    );
  }
}
