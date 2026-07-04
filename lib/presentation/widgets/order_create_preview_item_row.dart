import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/order_item_display.dart';
import 'order_create_preview_item.dart';

class OrderCreatePreviewItemRow extends StatelessWidget {
  const OrderCreatePreviewItemRow({super.key, required this.item});

  final OrderCreatePreviewItem item;

  @override
  Widget build(BuildContext context) {
    final codeLabel = productCodeDisplayLabel(item.code ?? '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceMuted),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                if (codeLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    codeLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            item.unit.isNotEmpty
                ? '${item.quantity} ${item.unit}'
                : item.quantity,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.turquoiseDark,
                ),
          ),
        ],
      ),
    );
  }
}

String buildCreateOrderPreviewSummary(int itemCount) {
  return '${AppStrings.orderItems}: $itemCount';
}
