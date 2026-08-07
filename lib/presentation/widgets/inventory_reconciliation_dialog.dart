import '../../core/utils/inventory_quantity.dart';

/// Строка для экрана сверки инвентаризации.
class InventoryReconciliationLine {
  const InventoryReconciliationLine({
    required this.name,
    required this.actualQuantity,
    this.accountingQuantity,
    this.unit,
    this.code,
  });

  final String name;
  final String? code;
  final String? unit;
  final double? accountingQuantity;
  final double actualQuantity;

  bool get hasMismatch =>
      InventoryQuantity.mismatches(actualQuantity, accountingQuantity);

  double? get difference {
    final accounting = accountingQuantity;
    if (accounting == null) return null;
    return InventoryQuantity.difference(actualQuantity, accounting);
  }
}
