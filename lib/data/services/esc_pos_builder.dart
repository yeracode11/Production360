import 'esc_pos_encoding.dart';

/// Сборка ESC/POS команд для чекового принтера 80 мм (48 символов, RK1048).
class EscPosBuilder {
  EscPosBuilder();

  static const lineWidth = 48;

  final List<int> _bytes = <int>[];

  List<int> build() => List<int>.unmodifiable(_bytes);

  void initialize() {
    _bytes.addAll([0x1B, 0x40]); // ESC @ — сброс
    _bytes.addAll([0x1B, 0x74, 6]); // Page 6 — RK1048 (KZ-1048)
  }

  void setAlign(int mode) => _bytes.addAll([0x1B, 0x61, mode]);

  void setBold(bool enabled) => _bytes.addAll([0x1B, 0x45, enabled ? 1 : 0]);

  void setTextSize({bool doubleWidth = false, bool doubleHeight = false}) {
    var mode = 0;
    if (doubleWidth) mode |= 0x20;
    if (doubleHeight) mode |= 0x10;
    _bytes.addAll([0x1D, 0x21, mode]);
  }

  void rawText(String text) => _bytes.addAll(EscPosEncoding.encode(text));

  void newline([int count = 1]) {
    for (var i = 0; i < count; i++) {
      _bytes.add(0x0A);
    }
  }

  void textLine(String text) {
    rawText(text);
    newline();
  }

  void wrappedText(String text, {int? width}) {
    for (final line in wrapText(text, width ?? lineWidth)) {
      textLine(line);
    }
  }

  void field(String label, String value) {
    final prefix = '$label: ';
    if (prefix.length + value.length <= lineWidth) {
      textLine('$prefix$value');
      return;
    }
    textLine(prefix.trimRight());
    wrappedText(value);
  }

  void separator() => textLine('-' * lineWidth);

  void feed(int lines) => _bytes.addAll([0x1B, 0x64, lines]);

  void cut() => _bytes.addAll([0x1D, 0x56, 0x00]);

  static List<String> wrapText(String text, int width) {
    final normalized = text.replaceAll('\n', ' ').trim();
    if (normalized.isEmpty) return const [];
    if (normalized.length <= width) return [normalized];

    final lines = <String>[];
    final buffer = StringBuffer();

    for (final word in normalized.split(RegExp(r'\s+'))) {
      if (buffer.isEmpty) {
        if (word.length <= width) {
          buffer.write(word);
        } else {
          var start = 0;
          while (start < word.length) {
            final end = (start + width).clamp(0, word.length);
            lines.add(word.substring(start, end));
            start = end;
          }
        }
        continue;
      }

      final candidate = '${buffer.toString()} $word';
      if (candidate.length <= width) {
        buffer.write(' $word');
      } else {
        lines.add(buffer.toString());
        buffer
          ..clear()
          ..write(word.length <= width ? word : '');
        if (word.length > width) {
          if (buffer.isNotEmpty) {
            lines.add(buffer.toString());
            buffer.clear();
          }
          var start = 0;
          while (start < word.length) {
            final end = (start + width).clamp(0, word.length);
            final chunk = word.substring(start, end);
            if (end == word.length && chunk.length <= width) {
              buffer.write(chunk);
            } else {
              lines.add(chunk);
            }
            start = end;
          }
        }
      }
    }

    if (buffer.isNotEmpty) {
      lines.add(buffer.toString());
    }
    return lines;
  }
}
