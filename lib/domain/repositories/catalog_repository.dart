import '../entities/order_type_product.dart';

/// Поиск номенклатуры на Production360 backend (PostgreSQL после синка из 1С).
abstract class CatalogRepository {
  Future<List<OrderTypeProduct>> searchNomenclature(
    String query, {
    int limit = 50,
  });
}
