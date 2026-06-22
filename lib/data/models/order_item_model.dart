import '../../domain/entities/order_item.dart';

class OrderItemModel extends OrderItem {
  const OrderItemModel({
    required super.name,
    required super.quantity,
    super.unit,
    super.id,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      unit: json['unit'] as String?,
    );
  }

  /// Parses «Товары» item from GET /mobile/zayavka?id= detail response.
  factory OrderItemModel.from1CProductJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: _readOptionalString(json, ['id', 'Ссылка', 'productId']),
      name: _readString(json, ['Наименование', 'name', 'Name']),
      quantity: _parseInt(json['amount'] ?? json['Количество']),
      unit: _readOptionalString(json, ['edIzm', 'ЕдИзм', 'unit']),
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

  static String? _readOptionalString(Map<String, dynamic> json, List<String> keys) {
    final value = _readString(json, keys);
    return value.isEmpty ? null : value;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.parse(value.toString());
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'quantity': quantity,
        if (unit != null) 'unit': unit,
      };
}
