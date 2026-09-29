import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/one_c_config.dart';
import '../../domain/services/force_update_notifier.dart';
import 'app_version_provider.dart';
import 'force_update_interceptor.dart';

/// Dio client for direct HTTP calls to 1C:Enterprise services.
class DioClient {
  DioClient({
    String? baseUrl,
    AppVersionProvider? versionProvider,
    ForceUpdateNotifier? forceUpdateNotifier,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? OneCConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (versionProvider != null && forceUpdateNotifier != null) {
      _dio.interceptors.add(
        ForceUpdateInterceptor(
          versionProvider: versionProvider,
          forceUpdateNotifier: forceUpdateNotifier,
        ),
      );
    }

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  late final Dio _dio;

  /// Таймаут POST-создания документов в 1С (проведение может занимать долго).
  static const documentCreateTimeout = Duration(seconds: 120);

  Options get documentCreateOptions => Options(
        connectTimeout: documentCreateTimeout,
        sendTimeout: documentCreateTimeout,
        receiveTimeout: documentCreateTimeout,
      );

  Dio get instance => _dio;

  bool get hasAuth => _dio.options.headers.containsKey('Authorization');

  void setBasicAuth(String username, String password) {
    _dio.options.headers['Authorization'] =
        'Basic ${base64.encode(utf8.encode('$username:$password'))}';
  }

  void clearAuth() {
    _dio.options.headers.remove('Authorization');
  }
}
