import '../../domain/entities/order_receipt_item.dart';

class OrderReceiptItemModel extends OrderReceiptItem {
  const OrderReceiptItemModel({
    required super.id,
    required super.name,
    required super.unit,
    required super.ordered,
    required super.shipped,
    required super.received,
    super.code,
  });

  factory OrderReceiptItemModel.from1CJson(Map<String, dynamic> json) {
    return OrderReceiptItemModel(
      id: _readString(json, ['id', 'Ссылка', 'productId']),
      name: _readString(json, ['Наименование', 'name', 'Name']),
      code: _readOptionalString(json, ['code', 'Код', 'Артикул']),
      unit: _readString(json, ['edIzm', 'ЕдИзм', 'unit']),
      ordered: _parseInt(json['ordered'] ?? json['Заказано']),
      shipped: _parseInt(json['shipped'] ?? json['Отгружено']),
      received: _parseInt(json['received'] ?? json['Получено']),
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
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.parse(value.toString());
  }
}
