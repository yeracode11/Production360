import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/amount_parser.dart';
import 'receipt_preview_item.dart';

class ReceiptPreviewItemRow extends StatelessWidget {
  const ReceiptPreviewItemRow({super.key, required this.item});

  final ReceiptPreviewItem item;

  @override
  Widget build(BuildContext context) {
    final isAccepted = item.accepted;
    final isRejected = item.rejected;
    final isPending = item.pending;

    final bgColor = isRejected
        ? AppColors.error.withValues(alpha: 0.1)
        : isAccepted
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.surfaceMuted.withValues(alpha: 0.35);
    final borderColor = isRejected
        ? AppColors.error.withValues(alpha: 0.45)
        : isAccepted
            ? AppColors.success.withValues(alpha: 0.45)
            : AppColors.surfaceMuted;
    final statusColor = isRejected
        ? AppColors.error
        : isAccepted
            ? AppColors.success
            : AppColors.textSecondary;
    final statusLabel = isRejected
        ? AppStrings.rejectItem
        : isAccepted
            ? AppStrings.acceptItem
            : AppStrings.receiptPreviewPending;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (item.name.trim().isNotEmpty)
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isPending
                              ? AppColors.textPrimary
                              : statusColor,
                        ),
                  ),
                ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${AppStrings.itemOrdered}: ${formatQuantityForInput(item.ordered)} ${item.unit} · '
            '${AppStrings.itemShipped}: ${formatQuantityForInput(item.shipped)} ${item.unit}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (isAccepted) ...[
            const SizedBox(height: 2),
            Text(
              '${AppStrings.itemReceived}: ${formatQuantityForInput(item.received)} ${item.unit}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

String buildReceiptPreviewSummary(List<ReceiptPreviewItem> items) {
  final acceptedCount =
      items.where((i) => i.status == ReceiptItemPreviewStatus.accepted).length;
  final rejectedCount =
      items.where((i) => i.status == ReceiptItemPreviewStatus.rejected).length;
  final pendingCount =
      items.where((i) => i.status == ReceiptItemPreviewStatus.pending).length;

  final summaryParts = <String>[
    '${AppStrings.receiptPreviewAccepted}: $acceptedCount',
    '${AppStrings.receiptPreviewRejected}: $rejectedCount',
  ];
  if (pendingCount > 0) {
    summaryParts.add('${AppStrings.receiptPreviewPending}: $pendingCount');
  }
  return summaryParts.join('  ·  ');
}
