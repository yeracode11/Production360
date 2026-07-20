import '../entities/nomenclature_page.dart';

/// Поиск номенклатуры на Production360 backend (PostgreSQL после синка из 1С).
abstract class CatalogRepository {
  /// Без [query] — список активных запасов батчами.
  /// С [query] — фильтр по названию / коду / артикулу.
  /// [organizationId] — организация склада (из predata 1С).
  Future<NomenclaturePage> searchNomenclature({
    required String organizationId,
    String? query,
    int limit = 30,
    int offset = 0,
  });
}
