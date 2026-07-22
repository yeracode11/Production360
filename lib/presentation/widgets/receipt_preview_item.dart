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
  final double ordered;
  final double shipped;
  final ReceiptItemPreviewStatus status;
  final double received;

  bool get accepted => status == ReceiptItemPreviewStatus.accepted;
  bool get rejected => status == ReceiptItemPreviewStatus.rejected;
  bool get pending => status == ReceiptItemPreviewStatus.pending;
}
