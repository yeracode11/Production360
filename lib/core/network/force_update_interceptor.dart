import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/services/force_update_notifier.dart';
import 'app_version_provider.dart';

/// Добавляет `X-App-Version` и реагирует на 426 / `version_restricted` от 1С.
class ForceUpdateInterceptor extends Interceptor {
  ForceUpdateInterceptor({
    required AppVersionProvider versionProvider,
    required ForceUpdateNotifier forceUpdateNotifier,
  })  : _versionProvider = versionProvider,
        _forceUpdateNotifier = forceUpdateNotifier;

  static const String appVersionHeader = 'X-App-Version';
  static const String versionRestrictedError = 'version_restricted';

  final AppVersionProvider _versionProvider;
  final ForceUpdateNotifier _forceUpdateNotifier;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final version = await _versionProvider.getVersion();
    options.headers[appVersionHeader] = version;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (_isForceUpdateResponse(response)) {
      _forceUpdateNotifier.notifyForceUpdateRequired();
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_isForceUpdateResponse(err.response)) {
      _forceUpdateNotifier.notifyForceUpdateRequired();
    }
    handler.next(err);
  }

  bool _isForceUpdateResponse(Response<dynamic>? response) {
    if (response == null) {
      return false;
    }

    if (response.statusCode == 426) {
      return true;
    }

    return _containsVersionRestrictedError(response.data);
  }

  bool _containsVersionRestrictedError(dynamic data) {
    if (data is Map) {
      return _errorValue(data['error']) == versionRestrictedError;
    }

    if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          return _errorValue(decoded['error']) == versionRestrictedError;
        }
      } on FormatException {
        return false;
      }
    }

    return false;
  }

  String? _errorValue(dynamic value) {
    if (value == null) {
      return null;
    }
    return value.toString();
  }
}
