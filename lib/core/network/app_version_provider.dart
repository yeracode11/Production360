import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Кэширует версию приложения из `package_info_plus` для заголовков HTTP.
class AppVersionProvider {
  /// Fallback при hot restart, когда нативный плагин ещё не зарегистрирован.
  /// Должен совпадать с `version` в pubspec.yaml.
  static const String fallbackVersion = '1.0.0';

  String? _cachedVersion;

  Future<String> getVersion() async {
    if (_cachedVersion != null) {
      return _cachedVersion!;
    }

    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      _cachedVersion = version.isNotEmpty ? version : fallbackVersion;
    } on MissingPluginException {
      _cachedVersion = fallbackVersion;
    } catch (_) {
      _cachedVersion = fallbackVersion;
    }

    return _cachedVersion!;
  }
}
