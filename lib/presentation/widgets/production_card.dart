import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/production_document.dart';
import '../screens/production/production_details_screen.dart';

class ProductionCard extends StatelessWidget {
  const ProductionCard({super.key, required this.document});

  final ProductionDocument document;

  @override
  Widget build(BuildContext context) {
    final dateLabel = document.dateDisplay ??
        '${document.date.day.toString().padLeft(2, '0')}.'
            '${document.date.month.toString().padLeft(2, '0')}.'
            '${document.date.year}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  ProductionDetailsScreen(productionId: document.id),
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
                    Icons.precision_manufacturing_outlined,
                    color: AppColors.deepBrownLight,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${AppStrings.productionNumber}${document.number}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _PostedChip(isPosted: document.isPosted),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(label: AppStrings.date, value: dateLabel),
              const SizedBox(height: 4),
              _InfoRow(
                label: AppStrings.warehouse,
                value: document.warehouseName,
              ),
              if (document.comment != null) ...[
                const SizedBox(height: 4),
                _InfoRow(label: AppStrings.comment, value: document.comment!),
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
        isPosted ? AppStrings.productionPosted : AppStrings.productionNotPosted,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color:
                  isPosted ? AppColors.turquoiseDark : AppColors.textSecondary,
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
