import 'dart:convert';

/// Parses JSON bodies returned by 1C HTTP services.
Map<String, dynamic> parseOneCJson(dynamic data) {
  if (data is Map<String, dynamic>) {
    return data;
  }
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  if (data is String && data.isNotEmpty) {
    return jsonDecode(data) as Map<String, dynamic>;
  }
  throw const FormatException('Неверный формат ответа от 1С');
}
