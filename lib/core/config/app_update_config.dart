/// Ссылки для принудительного обновления. Замените на реальные перед релизом.
abstract final class AppUpdateConfig {
  static const String androidPackageId =
      'com.confectionery.logistics.confectionery_logistics';

  /// Google Play (основная ссылка для Android).
  static const String androidPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidPackageId';


  /// App Store (замените id на реальный после публикации).
  static const String iosAppStoreUrl =
      'https://apps.apple.com/app/id0000000000';
}
