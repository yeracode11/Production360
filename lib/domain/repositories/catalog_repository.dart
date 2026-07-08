import '../entities/nomenclature_page.dart';

/// Поиск номенклатуры на Production360 backend (PostgreSQL после синка из 1С).
abstract class CatalogRepository {
  /// Без [query] — список активных запасов батчами.
  /// С [query] — фильтр по названию / коду / артикулу.
  Future<NomenclaturePage> searchNomenclature({
    String? query,
    int limit = 30,
    int offset = 0,
  });
}
