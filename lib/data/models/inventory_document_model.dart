import '../../core/utils/one_c_author.dart';
import '../../core/utils/one_c_bool.dart';
import '../../core/utils/one_c_date.dart';
import '../../domain/entities/inventory_document.dart';

class InventoryDocumentModel extends InventoryDocument {
  const InventoryDocumentModel({
    required super.id,
    required super.number,
    required super.date,
    required super.isPosted,
    required super.organizationId,
    required super.organizationName,
    required super.warehouseId,
    required super.warehouseName,
    super.comment,
    super.dateDisplay,
    super.author,
    super.authorLogin,
    super.items = const [],
  });

  factory InventoryDocumentModel.from1CListJson(Map<String, dynamic> json) {
    final dateRaw = json['Дата'] as String;
    final authorFields = OneCAuthorFields.parse(json);
    return InventoryDocumentModel(
      id: json['Ссылка'] as String,
      number: json['Номер'] as String,
      date: parseOneCDate(dateRaw),
      dateDisplay: dateRaw,
      isPosted: parseOneCBool(json['Проведен']),
      organizationId: json['ОрганизацияСсылка'] as String,
      organizationName: json['ОрганизацияНаименование'] as String,
      warehouseId: json['СкладСсылка'] as String,
      warehouseName: json['СкладНаименование'] as String,
      comment: _nullableString(json['Комментарий']),
      author: authorFields.name,
      authorLogin: authorFields.login,
    );
  }

  factory InventoryDocumentModel.from1CDetailJson(Map<String, dynamic> json) {
    final itemsJson = json['Товары'] as List<dynamic>? ?? [];
    final dateRaw = json['Дата'] as String?;
    final authorFields = OneCAuthorFields.parse(json);

    return InventoryDocumentModel(
      id: json['Ссылка'] as String,
      number: json['Номер'] as String,
      date: dateRaw != null ? parseOneCDate(dateRaw) : DateTime.now(),
      dateDisplay: dateRaw,
      isPosted: parseOneCBool(json['Проведен']),
      organizationId: json['ОрганизацияСсылка'] as String? ?? '',
      organizationName: json['ОрганизацияНаименование'] as String? ?? '',
      warehouseId: json['СкладСсылка'] as String? ?? '',
      warehouseName: json['СкладНаименование'] as String? ?? '',
      comment: _nullableString(json['Комментарий']),
      author: authorFields.name,
      authorLogin: authorFields.login,
      items: itemsJson
          .map(
            (e) => InventoryDocumentItemModel.from1CJson(
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

class InventoryDocumentItemModel extends InventoryDocumentItem {
  const InventoryDocumentItemModel({
    required super.productId,
    required super.name,
    required super.quantity,
    super.accountingQuantity,
    super.code,
    super.unit,
  });

  factory InventoryDocumentItemModel.from1CJson(Map<String, dynamic> json) {
    return InventoryDocumentItemModel(
      productId: json['НоменклатураСсылка'] as String,
      name: json['НоменклатураНаименование'] as String,
      quantity: (json['Количество'] as num).toDouble(),
      accountingQuantity: (json['КоличествоУчет'] as num?)?.toDouble(),
      code: json['НоменклатураКод'] as String?,
      unit: json['ЕдиницаИзмерения'] as String?,
    );
  }
}
