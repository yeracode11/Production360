/// Ссылки для принудительного обновления.
abstract final class AppUpdateConfig {
  static const String androidPackageId =
      'com.confectionery.logistics.confectionery_logistics';

  /// Apple App Store Connect → General → App Information → Apple ID.
  static const String iosAppStoreId = '6781777139';

  /// Регион публикации в App Store (Kazakhstan).
  static const String iosAppStoreCountryCode = 'kz';

  /// Google Play.
  static const String androidPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidPackageId';

  /// Открывает приложение Play Market на Android.
  static const String androidMarketUrl = 'market://details?id=$androidPackageId';

  /// Страница приложения в App Store KZ.
  static const String iosAppStoreUrl =
      'https://apps.apple.com/$iosAppStoreCountryCode/app/id$iosAppStoreId';

  /// Прямое открытие App Store на iPhone/iPad (KZ).
  static const String iosAppStoreDeepLink =
      'itms-apps://apps.apple.com/$iosAppStoreCountryCode/app/id$iosAppStoreId';

  /// Запасной вариант, если deep link не сработал.
  static const String iosAppStoreSearchUrl =
      'https://apps.apple.com/$iosAppStoreCountryCode/iphone/search?term=Production360';
}
