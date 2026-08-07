import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/printer_config.dart';

/// Локальное хранение принтера для каждого склада.
class PrinterConfigStorage {
  PrinterConfigStorage._({SharedPreferences? prefs}) : _prefs = prefs;

  final SharedPreferences? _prefs;
  final Map<String, _MemoryEntry> _memory = {};

  static Future<PrinterConfigStorage> create() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return PrinterConfigStorage._(prefs: prefs);
    } on MissingPluginException {
      return PrinterConfigStorage._();
    } catch (_) {
      return PrinterConfigStorage._();
    }
  }

  String _hostKey(String warehouseId) => 'printer_host_$warehouseId';
  String _portKey(String warehouseId) => 'printer_port_$warehouseId';
  String _nameKey(String warehouseId) => 'printer_name_$warehouseId';

  Future<void> save({
    required String warehouseId,
    required PrinterConfig config,
    String? printerName,
  }) async {
    final host = config.host.trim();
    if (warehouseId.isEmpty || host.isEmpty) return;

    if (_prefs != null) {
      await _prefs.setString(_hostKey(warehouseId), host);
      await _prefs.setInt(_portKey(warehouseId), config.port);
      if (printerName != null && printerName.trim().isNotEmpty) {
        await _prefs.setString(_nameKey(warehouseId), printerName.trim());
      } else {
        await _prefs.remove(_nameKey(warehouseId));
      }
      return;
    }

    _memory[warehouseId] = _MemoryEntry(
      host: host,
      port: config.port,
      name: printerName?.trim(),
    );
  }

  PrinterConfig? read(String warehouseId) {
    if (warehouseId.isEmpty) return null;

    if (_prefs != null) {
      final host = _prefs.getString(_hostKey(warehouseId))?.trim();
      if (host == null || host.isEmpty) return null;
      final port = _prefs.getInt(_portKey(warehouseId)) ?? PrinterConfig.defaultPort;
      return PrinterConfig(host: host, port: port);
    }

    final entry = _memory[warehouseId];
    if (entry == null || entry.host.isEmpty) return null;
    return PrinterConfig(host: entry.host, port: entry.port);
  }

  String? readPrinterName(String warehouseId) {
    if (warehouseId.isEmpty) return null;
    if (_prefs != null) {
      return _prefs.getString(_nameKey(warehouseId))?.trim();
    }
    return _memory[warehouseId]?.name;
  }
}

class _MemoryEntry {
  const _MemoryEntry({
    required this.host,
    required this.port,
    this.name,
  });

  final String host;
  final int port;
  final String? name;
}
