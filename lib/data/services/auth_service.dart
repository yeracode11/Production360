import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/config/one_c_config.dart';
import '../../core/constants/app_strings.dart';
import '../../core/network/dio_client.dart';
import '../models/user_model.dart';

/// HTTP requests to 1C:Enterprise authentication service.
class AuthService {
  AuthService({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  /// GET https://1c.darasoft.kz:8443/unf/unf/hs/mobile/auth
  Future<UserModel> login(String username, String password) async {
    final login = username.trim();
    if (login.isEmpty) {
      throw Exception('Введите логин');
    }

    _dioClient.clearAuth();
    _dioClient.setBasicAuth(login, password);

    try {
      final response = await _dioClient.instance.get(OneCConfig.authPath);
      final json = _parseResponse(response.data);
      return UserModel.from1CJson(json);
    } on DioException catch (e) {
      _dioClient.clearAuth();
      throw Exception(_mapDioError(e));
    }
  }

  Map<String, dynamic> _parseResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is String && data.isNotEmpty) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    throw Exception('Неверный формат ответа от 1С');
  }

  /// GET /mobile/auth — refreshes session and warehouse list from 1C.
  Future<UserModel> fetchSession() async {
    try {
      final response = await _dioClient.instance.get(OneCConfig.authPath);
      final json = _parseResponse(response.data);
      return UserModel.from1CJson(json);
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  String _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return AppStrings.invalidCredentials;
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Сервер 1С не отвечает. Проверьте подключение';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Не удалось подключиться к серверу';
    }
    final body = e.response?.data;
    if (body is String && body.isNotEmpty) {
      return body;
    }
    return e.message ?? AppStrings.authError;
  }
}
