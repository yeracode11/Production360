/// Parses 1C boolean values from JSON (`true`, `"true"`, `1`).
bool parseOneCBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1' || normalized == 'да') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'нет') {
    return false;
  }
  return defaultValue;
}
