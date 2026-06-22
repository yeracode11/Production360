/// Строка предпросмотра приёмки перед сохранением.
enum ReceiptItemPreviewStatus { pending, accepted, rejected }

class ReceiptPreviewItem {
  const ReceiptPreviewItem({
    required this.name,
    required this.unit,
    required this.ordered,
    required this.shipped,
    required this.status,
    required this.received,
  });

  final String name;
  final String unit;
  final int ordered;
  final int shipped;
  final ReceiptItemPreviewStatus status;
  final int received;

  bool get accepted => status == ReceiptItemPreviewStatus.accepted;
  bool get rejected => status == ReceiptItemPreviewStatus.rejected;
  bool get pending => status == ReceiptItemPreviewStatus.pending;
}
