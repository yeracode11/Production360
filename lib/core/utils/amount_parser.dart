/// Parses quantity text; supports comma as decimal separator.
num? parseAmount(String text) {
  final normalized = text.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return num.tryParse(normalized);
}

/// Formats amount for 1C POST body (string).
String? formatAmountFor1C(String text) {
  final value = parseAmount(text);
  if (value == null || value <= 0) return null;
  return value.toString();
}
