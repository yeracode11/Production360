import '../../core/utils/one_c_author.dart';
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
    super.rawMaterialsWarehouseName,
    super.departmentName,
    super.comment,
    super.dateDisplay,
    super.author,
    super.authorLogin,
    super.items = const [],
  });

  factory ProductionDocumentModel.from1CListJson(Map<String, dynamic> json) {
    final dateRaw = json['Дата'] as String?;
    final authorFields = OneCAuthorFields.parse(json);
    return ProductionDocumentModel(
      id: _requiredString(json, ['Ссылка']),
      number: _requiredString(json, ['Номер']),
      date: dateRaw != null ? parseOneCDate(dateRaw) : DateTime.now(),
      dateDisplay: dateRaw,
      isPosted: parseOneCBool(json['Проведен']),
      organizationId: _optionalString(json, [
        'ОрганизацияСсылка',
      ]) ??
          '',
      organizationName: _optionalString(json, [
            'ОрганизацияНаименование',
          ]) ??
          '',
      warehouseId: _optionalString(json, [
            'СкладПродукцииСсылка',
            'СкладСсылка',
          ]) ??
          '',
      warehouseName: _optionalString(json, [
            'СкладПродукцииНаименование',
            'СкладНаименование',
          ]) ??
          '',
      rawMaterialsWarehouseName: _optionalString(json, [
        'СкладСырьяНаименование',
      ]),
      departmentName: _optionalString(json, [
        'ПодразделениеНаименование',
      ]),
      comment: _nullableString(json['Комментарий']),
      author: authorFields.name,
      authorLogin: authorFields.login,
    );
  }

  factory ProductionDocumentModel.from1CDetailJson(Map<String, dynamic> json) {
    final itemsJson = json['Товары'] as List<dynamic>? ?? [];
    final dateRaw = json['Дата'] as String?;
    final authorFields = OneCAuthorFields.parse(json);

    return ProductionDocumentModel(
      id: _requiredString(json, ['Ссылка']),
      number: _requiredString(json, ['Номер']),
      date: dateRaw != null ? parseOneCDate(dateRaw) : DateTime.now(),
      dateDisplay: dateRaw,
      isPosted: parseOneCBool(json['Проведен']),
      organizationId: _optionalString(json, [
        'ОрганизацияСсылка',
      ]) ??
          '',
      organizationName: _optionalString(json, [
            'ОрганизацияНаименование',
          ]) ??
          '',
      warehouseId: _optionalString(json, [
            'СкладПродукцииСсылка',
            'СкладСсылка',
          ]) ??
          '',
      warehouseName: _optionalString(json, [
            'СкладПродукцииНаименование',
            'СкладНаименование',
          ]) ??
          '',
      rawMaterialsWarehouseName: _optionalString(json, [
        'СкладСырьяНаименование',
      ]),
      departmentName: _optionalString(json, [
        'ПодразделениеНаименование',
      ]),
      comment: _nullableString(json['Комментарий']),
      author: authorFields.name,
      authorLogin: authorFields.login,
      items: itemsJson
          .map(
            (e) => ProductionDocumentItemModel.from1CJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  static String _requiredString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    final value = _optionalString(json, keys);
    if (value == null || value.isEmpty) {
      throw FormatException('Missing required field: ${keys.first}');
    }
    return value;
  }

  static String? _optionalString(
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
    return null;
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
