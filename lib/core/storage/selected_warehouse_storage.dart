import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сохраняет выбранную торговую точку между запусками приложения.
class SelectedWarehouseStorage {
  SelectedWarehouseStorage._({SharedPreferences? prefs}) : _prefs = prefs;

  final SharedPreferences? _prefs;
  String? _memoryWarehouseId;
  String? _memoryWarehouseName;
  String? _memoryUserId;

  static const _warehouseIdKey = 'selected_warehouse_id';
  static const _warehouseNameKey = 'selected_warehouse_name';
  static const _userIdKey = 'selected_warehouse_user_id';

  /// Создаёт хранилище. При hot restart без нативного плагина — in-memory fallback.
  static Future<SelectedWarehouseStorage> create() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return SelectedWarehouseStorage._(prefs: prefs);
    } on MissingPluginException {
      return SelectedWarehouseStorage._();
    } catch (_) {
      return SelectedWarehouseStorage._();
    }
  }

  Future<void> save({
    required String userId,
    required String warehouseId,
    required String warehouseName,
  }) async {
    if (_prefs != null) {
      await _prefs.setString(_warehouseIdKey, warehouseId);
      await _prefs.setString(_warehouseNameKey, warehouseName);
      await _prefs.setString(_userIdKey, userId);
      return;
    }
    _memoryWarehouseId = warehouseId;
    _memoryWarehouseName = warehouseName;
    _memoryUserId = userId;
  }

  ({String? id, String? name}) readForUser(String userId) {
    if (_prefs != null) {
      final savedUserId = _prefs.getString(_userIdKey);
      if (savedUserId != userId) return (id: null, name: null);
      return (
        id: _prefs.getString(_warehouseIdKey),
        name: _prefs.getString(_warehouseNameKey),
      );
    }
    if (_memoryUserId != userId) return (id: null, name: null);
    return (id: _memoryWarehouseId, name: _memoryWarehouseName);
  }

  Future<void> clear() async {
    if (_prefs != null) {
      await _prefs.remove(_warehouseIdKey);
      await _prefs.remove(_warehouseNameKey);
      await _prefs.remove(_userIdKey);
    }
    _memoryWarehouseId = null;
    _memoryWarehouseName = null;
    _memoryUserId = null;
  }
}
