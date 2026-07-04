import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/services/force_update_notifier.dart';
import 'app_version_provider.dart';

/// Добавляет `X-App-Version` и реагирует на ответ 1С о необходимости обновления.
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
    final maps = _collectMaps(data);
    for (final map in maps) {
      if (_mapRequiresUpdate(map)) {
        return true;
      }
    }
    return false;
  }

  List<Map<String, dynamic>> _collectMaps(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      return [map];
    }

    if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          return [Map<String, dynamic>.from(decoded)];
        }
      } on FormatException {
        return const [];
      }
    }

    return const [];
  }

  bool _mapRequiresUpdate(Map<String, dynamic> map) {
    if (_isVersionRestrictedValue(map['error'])) {
      return true;
    }

    for (final key in ['error_code', 'errorCode', 'code']) {
      if (_isVersionRestrictedValue(map[key])) {
        return true;
      }
    }

    for (final key in ['error_text', 'errorText', 'message', 'detail']) {
      if (_textRequiresUpdate(map[key])) {
        return true;
      }
    }

    if (map['error'] == true &&
        (_textRequiresUpdate(map['error_text']) ||
            _textRequiresUpdate(map['errorText']))) {
      return true;
    }

    for (final key in [
      'update_required',
      'updateRequired',
      'ТребуетсяОбновление',
    ]) {
      final value = map[key];
      if (value == true || value == 1 || value?.toString() == 'true') {
        return true;
      }
    }

    return false;
  }

  bool _isVersionRestrictedValue(dynamic value) {
    if (value == null) {
      return false;
    }
    return value.toString().trim().toLowerCase() == versionRestrictedError;
  }

  bool _textRequiresUpdate(dynamic value) {
    if (value == null) {
      return false;
    }
    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) {
      return false;
    }
    return text.contains(versionRestrictedError) ||
        text.contains('обновлен') ||
        text.contains('update required');
  }
}
