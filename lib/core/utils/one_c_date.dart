/// Parses 1C datetime strings like «20260613190000» (YYYYMMDDHHmmss).
DateTime parseOneCDateTime(String value) {
  if (value.length < 14) {
    throw FormatException('Invalid 1C datetime: $value');
  }
  return DateTime(
    int.parse(value.substring(0, 4)),
    int.parse(value.substring(4, 6)),
    int.parse(value.substring(6, 8)),
    int.parse(value.substring(8, 10)),
    int.parse(value.substring(10, 12)),
    int.parse(value.substring(12, 14)),
  );
}

/// Parses 1C date strings like «12.06.2026 19:00:00» (dd.MM.yyyy HH:mm:ss).
DateTime parseOneCDateString(String value) {
  final trimmed = value.trim();
  final spaceIndex = trimmed.indexOf(' ');
  final datePart = spaceIndex == -1 ? trimmed : trimmed.substring(0, spaceIndex);
  final timePart = spaceIndex == -1 ? '00:00:00' : trimmed.substring(spaceIndex + 1);

  final dateParts = datePart.split('.');
  final timeParts = timePart.split(':');

  return DateTime(
    int.parse(dateParts[2]),
    int.parse(dateParts[1]),
    int.parse(dateParts[0]),
    int.parse(timeParts[0]),
    int.parse(timeParts[1]),
    int.parse(timeParts.length > 2 ? timeParts[2] : '0'),
  );
}

/// Парсит дату 1С: «20260611», «20260613190000» или «dd.MM.yyyy …».
DateTime parseOneCDate(String value) {
  final trimmed = value.trim();
  if (trimmed.length >= 8 && RegExp(r'^\d{8}').hasMatch(trimmed)) {
    return DateTime(
      int.parse(trimmed.substring(0, 4)),
      int.parse(trimmed.substring(4, 6)),
      int.parse(trimmed.substring(6, 8)),
    );
  }
  if (trimmed.length >= 14 &&
      RegExp(r'^\d{14}').hasMatch(trimmed.substring(0, 14))) {
    return parseOneCDateTime(trimmed.substring(0, 14));
  }
  return parseOneCDateString(trimmed);
}

/// Форматирует дату для 1С: «20260611» (YYYYMMDD).
String formatOneCDate(DateTime date) {
  return '${date.year}${_pad(date.month)}${_pad(date.day)}';
}

String _pad(int n) => n.toString().padLeft(2, '0');
