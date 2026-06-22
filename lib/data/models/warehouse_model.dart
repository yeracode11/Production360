import '../../domain/entities/warehouse.dart';

class WarehouseModel extends Warehouse {
  const WarehouseModel({
    required super.id,
    required super.name,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    return WarehouseModel(
      id: _readString(json, ['id', 'Ссылка', 'skladClientID']),
      name: _readString(json, ['name', 'Наименование', 'Имя']),
    );
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}
