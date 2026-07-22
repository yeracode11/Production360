import '../../core/utils/amount_parser.dart';
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
      ordered: parseAmountValue(json['ordered'] ?? json['Заказано']).toDouble(),
      shipped: parseAmountValue(json['shipped'] ?? json['Отгружено']).toDouble(),
      received: parseAmountValue(json['received'] ?? json['Получено']).toDouble(),
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
}
