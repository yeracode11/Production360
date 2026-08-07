import 'dart:developer' as developer;

/// Журнал операций печати (консоль + последние строки в UI).
abstract final class PrinterLog {
  static const _maxLines = 80;
  static const _name = 'Printer';

  static final List<String> _lines = <String>[];

  static List<String> get recentLines => List<String>.unmodifiable(_lines);

  static void clear() => _lines.clear();

  static void info(String message) => _write('INFO', message);

  static void warn(String message) => _write('WARN', message);

  static void error(String message) => _write('ERROR', message);

  static void _write(String level, String message) {
    final line =
        '${DateTime.now().toIso8601String().substring(11, 23)} [$level] $message';
    _lines.add(line);
    if (_lines.length > _maxLines) {
      _lines.removeAt(0);
    }
    developer.log(message, name: _name, level: _levelValue(level));
  }

  static int _levelValue(String level) {
    return switch (level) {
      'ERROR' => 1000,
      'WARN' => 900,
      _ => 800,
    };
  }
}
