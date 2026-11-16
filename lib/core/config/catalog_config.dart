/// Production360 catalog API — поиск номенклатуры (данные после синка из 1С).
abstract final class CatalogConfig {
  static const String baseUrl = 'https://p360.darasoft.kz';

  static const String nomenclatureSearchPath = '/nomenclature/search';

  /// Публичная проверка минимальной версии приложения.
  static const String appVersionPath = '/app/version';

  /// Токен только на чтение каталога (API_BEARER_TOKEN или MOBILE_BEARER_TOKEN
  /// на сервере). Права на /sync/* у него нет, если на сервере задан
  /// SYNC_BEARER_TOKEN.
  ///
  /// Новый токен при сборке: `flutter build ... --dart-define=CATALOG_BEARER_TOKEN=...`.
  /// Без dart-define используется прежний токен (выпущенные сборки не ломаются).
  static const String bearerToken = String.fromEnvironment(
    'CATALOG_BEARER_TOKEN',
    defaultValue:
        '99d5d06074fb41a04f2f5d6cef68db61502812e52e339bde33e05b0ac6f288e9',
  );
}
