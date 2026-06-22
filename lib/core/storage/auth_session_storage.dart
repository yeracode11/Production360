import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user_model.dart';

/// Сохраняет логин, пароль и снимок пользователя между запусками приложения.
class AuthSessionStorage {
  AuthSessionStorage._({SharedPreferences? prefs}) : _prefs = prefs;

  final SharedPreferences? _prefs;

  String? _memoryUsername;
  String? _memoryPassword;
  String? _memoryUserJson;

  static const _usernameKey = 'auth_username';
  static const _passwordKey = 'auth_password';
  static const _userJsonKey = 'auth_user_json';

  static Future<AuthSessionStorage> create() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return AuthSessionStorage._(prefs: prefs);
    } on MissingPluginException {
      return AuthSessionStorage._();
    } catch (_) {
      return AuthSessionStorage._();
    }
  }

  Future<void> saveSession({
    required String username,
    required String password,
    required UserModel user,
  }) async {
    final userJson = jsonEncode(user.to1CJson());
    if (_prefs != null) {
      await _prefs.setString(_usernameKey, username);
      await _prefs.setString(_passwordKey, password);
      await _prefs.setString(_userJsonKey, userJson);
      return;
    }
    _memoryUsername = username;
    _memoryPassword = password;
    _memoryUserJson = userJson;
  }

  Future<void> saveUserSnapshot(UserModel user) async {
    final userJson = jsonEncode(user.to1CJson());
    if (_prefs != null) {
      await _prefs.setString(_userJsonKey, userJson);
      return;
    }
    _memoryUserJson = userJson;
  }

  ({String username, String password})? readCredentials() {
    if (_prefs != null) {
      final username = _prefs.getString(_usernameKey);
      final password = _prefs.getString(_passwordKey);
      if (username == null ||
          username.isEmpty ||
          password == null ||
          password.isEmpty) {
        return null;
      }
      return (username: username, password: password);
    }
    if (_memoryUsername == null ||
        _memoryUsername!.isEmpty ||
        _memoryPassword == null ||
        _memoryPassword!.isEmpty) {
      return null;
    }
    return (username: _memoryUsername!, password: _memoryPassword!);
  }

  UserModel? readUserSnapshot() {
    final raw = _prefs?.getString(_userJsonKey) ?? _memoryUserJson;
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.from1CJson(json);
    } catch (_) {
      return null;
    }
  }

  bool hasStoredSession() => readCredentials() != null;

  Future<void> clear() async {
    if (_prefs != null) {
      await _prefs.remove(_usernameKey);
      await _prefs.remove(_passwordKey);
      await _prefs.remove(_userJsonKey);
    }
    _memoryUsername = null;
    _memoryPassword = null;
    _memoryUserJson = null;
  }
}
