/// Production360 catalog API — поиск номенклатуры (данные после синка из 1С).
abstract final class CatalogConfig {
  static const String baseUrl = 'https://p360.darasoft.kz';

  static const String nomenclatureSearchPath = '/nomenclature/search';

  /// Тот же токен, что API_BEARER_TOKEN на сервере.
  static const String bearerToken = 'замените-на-длинный-секретный-токен';
}
