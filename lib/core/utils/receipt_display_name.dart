import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_receipt_item.dart';

final _placeholderReceiptNamePattern = RegExp(r'^позици', caseSensitive: false);

/// Служебные названия из 1С («Позиция1», «Позиции») не показываем в UI.
bool isPlaceholderReceiptName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return true;
  }
  return _placeholderReceiptNamePattern.hasMatch(trimmed);
}

/// Реальное название для карточки приёмки: из товаров заказа, поля приёмки или кода.
String? receiptItemDisplayName({
  required OrderReceiptItem item,
  required List<OrderItem> orderItems,
}) {
  for (final orderItem in orderItems) {
    if (orderItem.id != null &&
        orderItem.id!.isNotEmpty &&
        orderItem.id == item.id &&
        !isPlaceholderReceiptName(orderItem.name)) {
      return orderItem.name;
    }
  }

  if (!isPlaceholderReceiptName(item.name)) {
    return item.name;
  }

  final code = item.code?.trim();
  if (code != null && code.isNotEmpty) {
    return code;
  }

  return null;
}
