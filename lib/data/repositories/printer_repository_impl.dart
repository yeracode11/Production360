import 'package:dio/dio.dart';

import '../../core/config/one_c_config.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/one_c_json.dart';
import '../../core/storage/printer_config_storage.dart';
import '../../core/utils/printer_log.dart';
import '../../domain/entities/printable_document.dart';
import '../../domain/entities/printer_config.dart';
import '../../domain/entities/warehouse_printer.dart';
import '../../domain/repositories/printer_repository.dart';
import '../models/warehouse_printer_model.dart';
import '../services/esc_pos_print_service.dart';
import '../services/network_printer_client.dart';

class PrinterNotConfiguredException implements Exception {
  PrinterNotConfiguredException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PrinterRepositoryImpl implements PrinterRepository {
  PrinterRepositoryImpl({
    required PrinterConfigStorage storage,
    required DioClient dioClient,
    EscPosPrintService? printService,
    NetworkPrinterClient? networkClient,
  })  : _storage = storage,
        _dioClient = dioClient,
        _printService = printService ?? EscPosPrintService(),
        _networkClient = networkClient ?? const NetworkPrinterClient();

  final PrinterConfigStorage _storage;
  final DioClient _dioClient;
  final EscPosPrintService _printService;
  final NetworkPrinterClient _networkClient;

  @override
  Future<List<WarehousePrinter>> fetchWarehousePrinters(
    String warehouseId,
  ) async {
    try {
      final response = await _dioClient.instance.get(
        OneCConfig.printersPath,
        queryParameters: {'skladID': warehouseId},
      );
      final json = parseOneCJson(response.data);
      _throwIfOneCError(json, 'Ошибка загрузки принтеров');

      final data = json['data'] as List<dynamic>? ?? [];
      return data
          .map(
            (e) => WarehousePrinterModel.from1CJson(
              e as Map<String, dynamic>,
            ),
          )
          .where((printer) => printer.address.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  @override
  Future<PrinterConfig?> getConfig(String warehouseId) async {
    final config = _storage.read(warehouseId);
    if (config != null) {
      final name = _storage.readPrinterName(warehouseId);
      PrinterLog.info(
        'Загружен конфиг склада $warehouseId: ${config.addressLabel}'
        '${name != null ? ' ($name)' : ''}',
      );
      return config.copyWith(displayName: name);
    }
    PrinterLog.warn('Конфиг принтера для склада $warehouseId не задан');
    return null;
  }

  @override
  Future<void> saveConfig({
    required String warehouseId,
    required PrinterConfig config,
    String? printerName,
  }) async {
    PrinterLog.info(
      'Сохранение конфига склада $warehouseId: ${config.addressLabel}',
    );
    await _storage.save(
      warehouseId: warehouseId,
      config: config,
      printerName: printerName,
    );
    PrinterLog.info('Конфиг сохранён');
  }

  @override
  Future<void> verifyConnection({
    required String warehouseId,
    required PrinterConfig config,
  }) async {
    if (!config.isConfigured) {
      throw PrinterNotConfiguredException(
        'Принтер не настроен. Укажите IP в настройках.',
      );
    }
    await _networkClient.verifyConnection(
      host: config.host,
      port: config.port,
    );
  }

  @override
  Future<void> printDocument(
    PrintableDocument document, {
    required String warehouseId,
  }) async {
    final config = await _requireConfig(warehouseId);
    PrinterLog.info(
      'Документ «${document.title}»: полей ${document.fields.length}, '
      'позиций ${document.items.length}',
    );
    final bytes = _printService.buildDocumentBytes(document);
    await _networkClient.send(
      host: config.host,
      port: config.port,
      data: bytes,
    );
  }

  @override
  Future<void> printTestPage(String warehouseId) async {
    final config = await _requireConfig(warehouseId);
    PrinterLog.info('Тестовая печать → ${config.addressLabel}');
    final bytes = _printService.buildTestPageBytes();
    PrinterLog.info('Сформировано ${bytes.length} байт тестового чека');
    await _networkClient.send(
      host: config.host,
      port: config.port,
      data: bytes,
    );
  }

  Future<PrinterConfig> _requireConfig(String warehouseId) async {
    if (warehouseId.isEmpty) {
      throw PrinterNotConfiguredException(
        'Не выбран склад для печати.',
      );
    }
    final config = await getConfig(warehouseId);
    if (config == null || !config.isConfigured) {
      PrinterLog.error('Печать отменена: принтер не настроен');
      throw PrinterNotConfiguredException(
        'Принтер не настроен для этого склада. Укажите IP в настройках.',
      );
    }
    return config;
  }

  void _throwIfOneCError(Map<String, dynamic> json, String fallback) {
    if (json['error'] == true) {
      throw Exception(json['error_text'] as String? ?? fallback);
    }
  }

  String _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return 'Неверный логин или пароль';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Сервер 1С не отвечает';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Не удалось подключиться к серверу';
    }
    final body = e.response?.data;
    if (body != null) {
      try {
        final json = parseOneCJson(body);
        if (json['error'] == true) {
          return json['error_text'] as String? ?? 'Ошибка запроса к 1С';
        }
      } catch (_) {}
    }
    return e.message ?? 'Ошибка запроса к 1С';
  }
}
