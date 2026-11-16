import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/one_c_author.dart';

/// Локальный кэш логина автора документа (если 1С не вернула «Автор»).
class DocumentAuthorStorage {
  DocumentAuthorStorage._({SharedPreferences? prefs}) : _prefs = prefs;

  final SharedPreferences? _prefs;
  final Map<String, String> _memory = {};

  static const _keyPrefix = 'document_author_';

  static Future<DocumentAuthorStorage> create() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return DocumentAuthorStorage._(prefs: prefs);
    } on MissingPluginException {
      return DocumentAuthorStorage._();
    } catch (_) {
      return DocumentAuthorStorage._();
    }
  }

  Future<void> save({
    required String documentId,
    required String login,
  }) async {
    final value = login.trim();
    if (documentId.isEmpty || value.isEmpty) return;
    if (OneCAuthorFields.isServiceAccount(value)) return;

    final key = '$_keyPrefix$documentId';
    if (_prefs != null) {
      await _prefs.setString(key, value);
      return;
    }
    _memory[documentId] = value;
  }

  String? read(String documentId) {
    if (documentId.isEmpty) return null;

    final value = _prefs != null
        ? _prefs.getString('$_keyPrefix$documentId')
        : _memory[documentId];
    // Старые версии могли закэшировать служебного пользователя 1С.
    if (value == null || OneCAuthorFields.isServiceAccount(value)) return null;
    return value;
  }
}
