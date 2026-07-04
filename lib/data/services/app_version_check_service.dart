import 'package:dio/dio.dart';

import '../../core/config/catalog_config.dart';
import '../../core/network/app_version_provider.dart';
import '../../core/utils/version_comparator.dart';
import '../../domain/services/force_update_notifier.dart';

/// Проверяет минимальную версию на backend (p360) при старте приложения.
class AppVersionCheckService {
  AppVersionCheckService({
    required AppVersionProvider versionProvider,
    required ForceUpdateNotifier forceUpdateNotifier,
    Dio? dio,
  })  : _versionProvider = versionProvider,
        _forceUpdateNotifier = forceUpdateNotifier,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: CatalogConfig.baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: const {
                  'Accept': 'application/json',
                },
              ),
            );

  final AppVersionProvider _versionProvider;
  final ForceUpdateNotifier _forceUpdateNotifier;
  final Dio _dio;

  Future<void> checkMinVersion() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        CatalogConfig.appVersionPath,
      );
      final minVersion = _readMinVersion(response.data);
      if (minVersion == null || minVersion.isEmpty) {
        return;
      }

      final currentVersion = await _versionProvider.getVersion();
      if (isAppVersionLower(currentVersion, minVersion)) {
        _forceUpdateNotifier.notifyForceUpdateRequired();
      }
    } catch (_) {
      // Не блокируем приложение при недоступности backend.
    }
  }

  String? _readMinVersion(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }

    for (final key in ['min_version', 'minVersion', 'minimum_version']) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }
}
