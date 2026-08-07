import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';

/// Баннер сверху списка при наличии расхождений.
class InventoryMismatchBanner extends StatelessWidget {
  const InventoryMismatchBanner({super.key, required this.mismatchCount});

  final int mismatchCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.mismatchSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.mismatchBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.difference_outlined,
            size: 20,
            color: AppColors.mismatchAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppStrings.inventoryReconciliationMismatchHint(mismatchCount),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mismatchText,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Баннер, когда все позиции совпадают.
class InventoryMatchBanner extends StatelessWidget {
  const InventoryMatchBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.successBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 20,
            color: AppColors.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppStrings.inventoryReconciliationMatchHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Бейдж «Расхождение» для строки.
class InventoryMismatchBadge extends StatelessWidget {
  const InventoryMismatchBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.mismatchAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.mismatchBorder.withValues(alpha: 0.8),
        ),
      ),
      child: Text(
        AppStrings.inventoryMismatchBadge,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.mismatchText,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
      ),
    );
  }
}

/// Обёртка карточки позиции с акцентной полосой при расхождении.
class InventoryMismatchCard extends StatelessWidget {
  const InventoryMismatchCard({
    super.key,
    required this.hasMismatch,
    required this.child,
    this.margin = const EdgeInsets.only(bottom: 8),
  });

  final bool hasMismatch;
  final Widget child;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: hasMismatch ? AppColors.mismatchSoft : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasMismatch ? AppColors.mismatchBorder : AppColors.surfaceMuted,
        ),
        boxShadow: hasMismatch
            ? [
                BoxShadow(
                  color: AppColors.mismatchAccent.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasMismatch)
              Container(
                width: 4,
                color: AppColors.mismatchAccent,
              ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// Подсветка строки с разницей количества.
class InventoryDifferenceHighlight extends StatelessWidget {
  const InventoryDifferenceHighlight({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.mismatchAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.mismatchBorder.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: theme.bodySmall?.copyWith(
              color: AppColors.mismatchText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.bodyMedium?.copyWith(
              color: AppColors.mismatchText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
