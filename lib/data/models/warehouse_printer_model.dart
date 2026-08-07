import '../../domain/entities/warehouse_printer.dart';

class WarehousePrinterModel extends WarehousePrinter {
  const WarehousePrinterModel({
    required super.address,
    required super.name,
  });

  factory WarehousePrinterModel.from1CJson(Map<String, dynamic> json) {
    return WarehousePrinterModel(
      address: (json['address'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
    );
  }
}
