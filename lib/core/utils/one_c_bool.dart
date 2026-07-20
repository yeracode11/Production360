/// Разбор булевых значений из JSON 1С (bool, 0/1, "true"/"false").
bool parseOneCBool(dynamic value, {bool defaultValue = false}) {
  if (value is bool) return value;
  if (value == null) return defaultValue;
  final normalized = value.toString().trim().toLowerCase();
  if (normalized.isEmpty) return defaultValue;
  return normalized == 'true' ||
      normalized == '1' ||
      normalized == 'yes' ||
      normalized == 'да';
}
