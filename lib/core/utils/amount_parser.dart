/// Parses quantity text; supports comma as decimal separator.
num? parseAmount(String text) {
  final normalized = text.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return num.tryParse(normalized);
}

/// Parses quantity from JSON (int, double, or string).
num parseAmountValue(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  return parseAmount(value.toString()) ?? 0;
}

/// Formats quantity for text fields in the app (comma as decimal separator).
String formatQuantityForInput(num value) {
  if (value == 0) return '0';
  final text = value == value.roundToDouble()
      ? value.round().toString()
      : value.toString();
  return text.replaceAll('.', ',');
}

/// Formats quantity for 1C API (dot as decimal separator).
String formatQuantityFor1C(num value) {
  if (value <= 0) return '0';
  return value == value.roundToDouble()
      ? value.round().toString()
      : value.toString();
}

/// Formats amount for 1C POST body (string).
String? formatAmountFor1C(String text) {
  final value = parseAmount(text);
  if (value == null || value <= 0) return null;
  return formatQuantityFor1C(value);
}

/// Сумма/цена в тенге для отображения в UI.
String formatTengeAmount(double? value) {
  if (value == null) return '';
  final amount = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
  return '$amount ₸';
}
