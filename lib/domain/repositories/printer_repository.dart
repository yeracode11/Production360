import '../entities/printable_document.dart';
import '../entities/printer_config.dart';
import '../entities/warehouse_printer.dart';

abstract class PrinterRepository {
  Future<List<WarehousePrinter>> fetchWarehousePrinters(String warehouseId);

  Future<PrinterConfig?> getConfig(String warehouseId);

  Future<void> saveConfig({
    required String warehouseId,
    required PrinterConfig config,
    String? printerName,
  });

  Future<void> printDocument(
    PrintableDocument document, {
    required String warehouseId,
  });

  Future<void> printTestPage(String warehouseId);

  /// Проверка TCP без печати (для диагностики).
  Future<void> verifyConnection({
    required String warehouseId,
    required PrinterConfig config,
  });
}
