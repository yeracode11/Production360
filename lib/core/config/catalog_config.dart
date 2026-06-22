/// Production360 catalog API — поиск номенклатуры (данные после синка из 1С).
abstract final class CatalogConfig {
  /// Локально: iOS Simulator — 127.0.0.1, Android Emulator — 10.0.2.2.
  /// Прод: URL вашего backend-сервера.
  static const String baseUrl = 'http://127.0.0.1:8000';

  static const String nomenclatureSearchPath = '/nomenclature/search';
}
