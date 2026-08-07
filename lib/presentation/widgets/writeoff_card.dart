import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/stock_writeoff.dart';
import '../screens/writeoffs/writeoff_details_screen.dart';
import 'document_author_row.dart';

class WriteoffCard extends StatelessWidget {
  const WriteoffCard({
    super.key,
    required this.writeoff,
    this.onReturnFromDetails,
  });

  final StockWriteoff writeoff;
  final VoidCallback? onReturnFromDetails;

  @override
  Widget build(BuildContext context) {
    final dateLabel = writeoff.dateDisplay ??
        '${writeoff.date.day.toString().padLeft(2, '0')}.'
            '${writeoff.date.month.toString().padLeft(2, '0')}.'
            '${writeoff.date.year}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => WriteoffDetailsScreen(writeoffId: writeoff.id),
            ),
          );
          onReturnFromDetails?.call();
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
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(label: AppStrings.date, value: dateLabel),
              const SizedBox(height: 4),
              DocumentCardAuthorRow(
                documentId: writeoff.id,
                authorLogin: writeoff.authorLogin,
                author: writeoff.author,
              ),
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
