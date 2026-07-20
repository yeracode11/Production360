import '../entities/nomenclature_page.dart';

/// Поиск номенклатуры на Production360 backend (PostgreSQL после синка из 1С).
abstract class CatalogRepository {
  /// Глобальный поиск товаров по названию / коду / артикулу.
  Future<NomenclaturePage> searchNomenclature({
    required String organizationId,
    required String query,
    int limit = 30,
    int offset = 0,
  });

  /// Папки номенклатуры: [parentId] null — корневые группы.
  Future<NomenclaturePage> listNomenclatureGroups({
    required String organizationId,
    String? parentId,
    int limit = 100,
    int offset = 0,
  });

  /// Товары внутри выбранной группы ([parentId]).
  Future<NomenclaturePage> listNomenclatureProducts({
    required String organizationId,
    required String parentId,
    int limit = 30,
    int offset = 0,
  });
}
