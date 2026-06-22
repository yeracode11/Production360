import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/week_range.dart';

/// Карточка выбора недели для вкладки «Завершен».
class CompletedWeekFilter extends StatelessWidget {
  const CompletedWeekFilter({
    super.key,
    required this.weekStart,
    required this.weekEnd,
    required this.onWeekSelected,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final ValueChanged<DateTime> onWeekSelected;

  Future<void> _openDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('ru'),
      initialDate: _pickerInitialDate(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: AppStrings.selectWeekHint,
    );
    if (picked != null) {
      onWeekSelected(picked);
    }
  }

  DateTime _pickerInitialDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (WeekRange.containsDate(today, weekStart, weekEnd)) {
      return today;
    }
    return weekStart;
  }

  String get _periodLabel {
    final range = WeekRange(start: weekStart, end: weekEnd);
    return '${AppStrings.period}: ${range.formatRange()}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Material(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.surfaceMuted),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openDatePicker(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 22,
                  color: AppColors.turquoiseDark,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _periodLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.turquoise,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
