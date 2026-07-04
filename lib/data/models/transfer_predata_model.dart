import '../../domain/entities/transfer_predata.dart';

class TransferPredataModel extends TransferPredata {
  const TransferPredataModel({
    required super.organizationId,
    required super.organizationName,
    required super.availableWarehouses,
  });

  factory TransferPredataModel.from1CJson(Map<String, dynamic> json) {
    final warehousesJson = json['ДоступныеСклады'] as List<dynamic>? ?? [];
    return TransferPredataModel(
      organizationId: json['ОрганизацияСсылка'] as String,
      organizationName: json['ОрганизацияНаименование'] as String,
      availableWarehouses: warehousesJson
          .map(
            (e) => TransferWarehouseOptionModel.from1CJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class TransferWarehouseOptionModel extends TransferWarehouseOption {
  const TransferWarehouseOptionModel({
    required super.id,
    required super.name,
  });

  factory TransferWarehouseOptionModel.from1CJson(Map<String, dynamic> json) {
    return TransferWarehouseOptionModel(
      id: json['СкладСсылка'] as String,
      name: json['СкладНаименование'] as String,
    );
  }
}
