/// Строка предпросмотра заказа перед созданием.
class OrderCreatePreviewItem {
  const OrderCreatePreviewItem({
    required this.name,
    required this.quantity,
    required this.unit,
    this.code,
  });

  final String name;
  final String quantity;
  final String unit;
  final String? code;
}
