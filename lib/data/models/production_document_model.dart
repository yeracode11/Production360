import '../../core/utils/one_c_bool.dart';
import '../../core/utils/one_c_date.dart';
import '../../domain/entities/production_document.dart';

class ProductionDocumentModel extends ProductionDocument {
  const ProductionDocumentModel({
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
    super.items = const [],
  });

  factory ProductionDocumentModel.from1CListJson(Map<String, dynamic> json) {
    final dateRaw = json['Дата'] as String;
    return ProductionDocumentModel(
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
    );
  }

  factory ProductionDocumentModel.from1CDetailJson(Map<String, dynamic> json) {
    final itemsJson = json['Товары'] as List<dynamic>? ?? [];
    final dateRaw = json['Дата'] as String?;

    return ProductionDocumentModel(
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
      items: itemsJson
          .map(
            (e) => ProductionDocumentItemModel.from1CJson(
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

class ProductionDocumentItemModel extends ProductionDocumentItem {
  const ProductionDocumentItemModel({
    required super.productId,
    required super.name,
    required super.quantity,
    super.code,
    super.unit,
  });

  factory ProductionDocumentItemModel.from1CJson(Map<String, dynamic> json) {
    return ProductionDocumentItemModel(
      productId: json['НоменклатураСсылка'] as String,
      name: json['НоменклатураНаименование'] as String,
      quantity: (json['Количество'] as num).toDouble(),
      code: json['НоменклатураКод'] as String?,
      unit: json['ЕдиницаИзмерения'] as String?,
    );
  }
}
