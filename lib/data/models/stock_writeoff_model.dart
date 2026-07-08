import '../../core/utils/one_c_date.dart';
import '../../domain/entities/stock_writeoff.dart';

class StockWriteoffModel extends StockWriteoff {
  const StockWriteoffModel({
    required super.id,
    required super.number,
    required super.date,
    required super.isPosted,
    required super.organizationId,
    required super.organizationName,
    required super.warehouseId,
    required super.warehouseName,
    super.reasonId,
    super.reasonName,
    super.comment,
    super.dateDisplay,
    super.items = const [],
  });

  factory StockWriteoffModel.from1CListJson(Map<String, dynamic> json) {
    final dateRaw = json['Дата'] as String;
    return StockWriteoffModel(
      id: json['Ссылка'] as String,
      number: json['Номер'] as String,
      date: parseOneCDate(dateRaw),
      dateDisplay: dateRaw,
      isPosted: json['Проведен'] as bool? ?? false,
      organizationId: json['ОрганизацияСсылка'] as String,
      organizationName: json['ОрганизацияНаименование'] as String,
      warehouseId: json['СкладСсылка'] as String,
      warehouseName: json['СкладНаименование'] as String,
      reasonId: _nullableString(json['ПричинаСписанияСсылка']) ??
          _nullableString(json['ПричинаСсылка']),
      reasonName: _nullableString(json['ПричинаСписанияНаименование']) ??
          _nullableString(json['ПричинаНаименование']),
      comment: _nullableString(json['Комментарий']),
    );
  }

  factory StockWriteoffModel.from1CDetailJson(Map<String, dynamic> json) {
    final itemsJson = json['Товары'] as List<dynamic>? ?? [];
    final dateRaw = json['Дата'] as String?;

    return StockWriteoffModel(
      id: json['Ссылка'] as String,
      number: json['Номер'] as String,
      date: dateRaw != null ? parseOneCDate(dateRaw) : DateTime.now(),
      dateDisplay: dateRaw,
      isPosted: json['Проведен'] as bool? ?? false,
      organizationId: json['ОрганизацияСсылка'] as String? ?? '',
      organizationName: json['ОрганизацияНаименование'] as String? ?? '',
      warehouseId: json['СкладСсылка'] as String? ?? '',
      warehouseName: json['СкладНаименование'] as String? ?? '',
      reasonId: _nullableString(json['ПричинаСписанияСсылка']) ??
          _nullableString(json['ПричинаСсылка']),
      reasonName: _nullableString(json['ПричинаСписанияНаименование']) ??
          _nullableString(json['ПричинаНаименование']),
      comment: _nullableString(json['Комментарий']),
      items: itemsJson
          .map(
            (e) => StockWriteoffItemModel.from1CJson(
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

class StockWriteoffItemModel extends StockWriteoffItem {
  const StockWriteoffItemModel({
    required super.productId,
    required super.name,
    required super.quantity,
    super.code,
    super.unit,
  });

  factory StockWriteoffItemModel.from1CJson(Map<String, dynamic> json) {
    return StockWriteoffItemModel(
      productId: json['НоменклатураСсылка'] as String,
      name: json['НоменклатураНаименование'] as String,
      quantity: (json['Количество'] as num).toDouble(),
      code: json['НоменклатураКод'] as String?,
      unit: json['ЕдиницаИзмерения'] as String?,
    );
  }
}
