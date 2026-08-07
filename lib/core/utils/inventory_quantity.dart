/// Сравнение количеств инвентаризации (учёт vs факт).
abstract final class InventoryQuantity {
  static const _epsilon = 0.0005;

  static bool matches(double actual, double accounting) {
    return (actual - accounting).abs() <= _epsilon;
  }

  static bool mismatches(double? actual, double? accounting) {
    if (actual == null || accounting == null) return false;
    return !matches(actual, accounting);
  }

  static double difference(double actual, double accounting) =>
      actual - accounting;
}
