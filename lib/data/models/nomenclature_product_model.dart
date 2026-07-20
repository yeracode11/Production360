import '../../core/utils/one_c_bool.dart';
import '../../domain/entities/nomenclature_product.dart';

class NomenclatureProductModel extends NomenclatureProduct {
  const NomenclatureProductModel({
    required super.id,
    required super.name,
    required super.code,
    required super.unit,
    super.showInMobileApp,
    super.usagePlaces,
  });

  factory NomenclatureProductModel.fromCatalogJson(Map<String, dynamic> json) {
    return NomenclatureProductModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      code: json['code'] as String? ?? '',
      unit: json['edIzm'] as String? ?? '',
      showInMobileApp: parseOneCBool(
        json['showInMobileApp'] ?? json['ОтображатьВМобильнымПриложении'],
        defaultValue: true,
      ),
      usagePlaces: parseNomenclatureUsagePlaces(
        json['usagePlaces'] ?? json['МестаИспользования'],
      ),
    );
  }
}

List<NomenclatureUsagePlace> parseNomenclatureUsagePlaces(dynamic raw) {
  if (raw is! List<dynamic>) return const [];

  final places = <NomenclatureUsagePlace>[];
  final seen = <String>{};

  for (final entry in raw) {
    if (entry is! Map<String, dynamic>) continue;

    final type = _nullableString(entry['type']) ?? '';
    final id = _nullableString(entry['id']) ?? '';
    final name = _nullableString(entry['name']) ?? '';
    if (name.isEmpty) continue;

    final dedupeKey = id.isNotEmpty ? id : '$type|$name';
    if (!seen.add(dedupeKey)) continue;

    places.add(NomenclatureUsagePlace(type: type, id: id, name: name));
  }
  return places;
}

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
