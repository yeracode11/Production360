import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/nomenclature_product.dart';

/// Позиция черновика инвентаризации.
class InventoryDraftItem {
  const InventoryDraftItem({required this.product, this.quantityText = ''});

  final NomenclatureProduct product;

  /// Введённое количество как текст (может быть пустым — ещё не посчитали).
  final String quantityText;

  Map<String, dynamic> toJson() => {
        'id': product.id,
        'name': product.name,
        'code': product.code,
        'unit': product.unit,
        'parentId': product.parentId,
        'quantity': quantityText,
      };

  static InventoryDraftItem? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id']?.toString() ?? '';
    if (id.isEmpty) return null;
    return InventoryDraftItem(
      product: NomenclatureProduct(
        id: id,
        name: raw['name']?.toString() ?? '',
        code: raw['code']?.toString() ?? '',
        unit: raw['unit']?.toString() ?? '',
        parentId: raw['parentId']?.toString(),
      ),
      quantityText: raw['quantity']?.toString() ?? '',
    );
  }
}

/// Черновик инвентаризации для конкретного склада.
class InventoryDraft {
  const InventoryDraft({
    required this.warehouseId,
    required this.items,
    required this.savedAt,
    this.comment = '',
  });

  final String warehouseId;
  final String comment;
  final List<InventoryDraftItem> items;
  final DateTime savedAt;

  bool get isEmpty => items.isEmpty && comment.trim().isEmpty;

  Map<String, dynamic> toJson() => {
        'warehouseId': warehouseId,
        'comment': comment,
        'savedAt': savedAt.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
      };

  static InventoryDraft? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final warehouseId = raw['warehouseId']?.toString() ?? '';
    if (warehouseId.isEmpty) return null;
    final rawItems = raw['items'];
    final items = <InventoryDraftItem>[];
    if (rawItems is List) {
      for (final entry in rawItems) {
        final item = InventoryDraftItem.fromJson(entry);
        if (item != null) items.add(item);
      }
    }
    return InventoryDraft(
      warehouseId: warehouseId,
      comment: raw['comment']?.toString() ?? '',
      items: items,
      savedAt: DateTime.tryParse(raw['savedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// Локальные черновики инвентаризации (по одному на склад).
///
/// Хранятся в SharedPreferences, переживают перезапуск приложения,
/// но удаляются при выходе из аккаунта ([clearAll]).
class InventoryDraftStorage {
  InventoryDraftStorage._({SharedPreferences? prefs}) : _prefs = prefs;

  final SharedPreferences? _prefs;
  final Map<String, String> _memory = {};

  /// Увеличивается при любом изменении черновиков — для обновления UI.
  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static const _keyPrefix = 'inventory_draft_';

  static Future<InventoryDraftStorage> create() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return InventoryDraftStorage._(prefs: prefs);
    } on MissingPluginException {
      return InventoryDraftStorage._();
    } catch (_) {
      return InventoryDraftStorage._();
    }
  }

  InventoryDraft? read(String warehouseId) {
    if (warehouseId.isEmpty) return null;
    final key = '$_keyPrefix$warehouseId';
    final raw = _prefs != null ? _prefs.getString(key) : _memory[key];
    if (raw == null || raw.isEmpty) return null;
    try {
      return InventoryDraft.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  bool hasDraft(String warehouseId) => read(warehouseId) != null;

  Future<void> save(InventoryDraft draft) async {
    if (draft.warehouseId.isEmpty) return;
    final key = '$_keyPrefix${draft.warehouseId}';
    final raw = jsonEncode(draft.toJson());
    if (_prefs != null) {
      await _prefs.setString(key, raw);
    } else {
      _memory[key] = raw;
    }
    changes.value++;
  }

  Future<void> delete(String warehouseId) async {
    if (warehouseId.isEmpty) return;
    final key = '$_keyPrefix$warehouseId';
    if (_prefs != null) {
      await _prefs.remove(key);
    } else {
      _memory.remove(key);
    }
    changes.value++;
  }

  /// Удалить все черновики (вызывается при выходе из аккаунта).
  Future<void> clearAll() async {
    if (_prefs != null) {
      final keys =
          _prefs.getKeys().where((k) => k.startsWith(_keyPrefix)).toList();
      for (final key in keys) {
        await _prefs.remove(key);
      }
    }
    _memory.clear();
    changes.value++;
  }
}
