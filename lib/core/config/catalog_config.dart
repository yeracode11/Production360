/// Production360 catalog API — поиск номенклатуры (данные после синка из 1С).
abstract final class CatalogConfig {
  static const String baseUrl = 'https://p360.darasoft.kz';

  static const String nomenclatureSearchPath = '/nomenclature/search';

  /// Публичная проверка минимальной версии приложения.
  static const String appVersionPath = '/app/version';

  /// Тот же токен, что API_BEARER_TOKEN на сервере.
  static const String bearerToken = '99d5d06074fb41a04f2f5d6cef68db61502812e52e339bde33e05b0ac6f288e9';
}
