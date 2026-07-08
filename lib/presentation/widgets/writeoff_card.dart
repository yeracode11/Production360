import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/stock_writeoff.dart';
import '../screens/writeoffs/writeoff_details_screen.dart';

class WriteoffCard extends StatelessWidget {
  const WriteoffCard({super.key, required this.writeoff});

  final StockWriteoff writeoff;

  @override
  Widget build(BuildContext context) {
    final dateLabel = writeoff.dateDisplay ??
        '${writeoff.date.day.toString().padLeft(2, '0')}.'
            '${writeoff.date.month.toString().padLeft(2, '0')}.'
            '${writeoff.date.year}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => WriteoffDetailsScreen(writeoffId: writeoff.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.remove_circle_outline,
                    color: AppColors.deepBrownLight,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${AppStrings.writeoffNumber}${writeoff.number}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _PostedChip(isPosted: writeoff.isPosted),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(label: AppStrings.date, value: dateLabel),
              const SizedBox(height: 4),
              _InfoRow(
                label: AppStrings.warehouse,
                value: writeoff.warehouseName,
              ),
              if (writeoff.reasonName != null) ...[
                const SizedBox(height: 4),
                _InfoRow(
                  label: AppStrings.writeoffReason,
                  value: writeoff.reasonName!,
                ),
              ],
              if (writeoff.comment != null) ...[
                const SizedBox(height: 4),
                _InfoRow(label: AppStrings.comment, value: writeoff.comment!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PostedChip extends StatelessWidget {
  const _PostedChip({required this.isPosted});

  final bool isPosted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPosted ? AppColors.mintSoft : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPosted ? AppStrings.writeoffPosted : AppStrings.writeoffNotPosted,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isPosted ? AppColors.turquoiseDark : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.deepBrownLight,
              ),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
