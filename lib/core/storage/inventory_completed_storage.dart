import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Локальный список завершённых документов инвентаризации.
class InventoryCompletedStorage {
  InventoryCompletedStorage._({SharedPreferences? prefs}) : _prefs = prefs;

  final SharedPreferences? _prefs;
  final Set<String> _memory = {};

  static const _keyPrefix = 'inventory_completed_';

  static Future<InventoryCompletedStorage> create() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return InventoryCompletedStorage._(prefs: prefs);
    } on MissingPluginException {
      return InventoryCompletedStorage._();
    } catch (_) {
      return InventoryCompletedStorage._();
    }
  }

  bool isCompleted(String documentId) {
    if (documentId.isEmpty) return false;
    if (_prefs != null) {
      return _prefs.getBool('$_keyPrefix$documentId') ?? false;
    }
    return _memory.contains(documentId);
  }

  Future<void> markCompleted(String documentId) async {
    if (documentId.isEmpty) return;
    if (_prefs != null) {
      await _prefs.setBool('$_keyPrefix$documentId', true);
      return;
    }
    _memory.add(documentId);
  }
}
