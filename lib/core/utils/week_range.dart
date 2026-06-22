/// Диапазон одной календарной недели (Пн 00:00 — Вс 23:59:59).
class WeekRange {
  const WeekRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  /// Текущая неделя (от понедельника до воскресенья включительно).
  static WeekRange current() => fromDate(DateTime.now());

  /// Находит понедельник и воскресенье недели, в которую попадает [selectedDate].
  ///
  /// DateTime.weekday: Monday = 1, Sunday = 7.
  /// start = selectedDate − (weekday − 1) дней, время 00:00:00.
  /// end   = selectedDate + (7 − weekday) дней, время 23:59:59.
  static WeekRange fromDate(DateTime selectedDate) {
    final date = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final startOfWeek = date.subtract(
      Duration(days: date.weekday - DateTime.monday),
    );
    final endOfWeek = date.add(
      Duration(days: DateTime.sunday - date.weekday),
    );

    return WeekRange(
      start: DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      ),
      end: DateTime(
        endOfWeek.year,
        endOfWeek.month,
        endOfWeek.day,
        23,
        59,
        59,
      ),
    );
  }

  /// Проверяет, попадает ли [date] в диапазон [start]–[end] (по календарным дням).
  static bool containsDate(DateTime date, DateTime start, DateTime end) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  String formatRange() {
    return '${_fmt(start)} - ${_fmt(end)}';
  }

  static String _fmt(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.'
        '${d.year}';
  }
}
