import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/inventory_document.dart';
import '../screens/inventory/inventory_details_screen.dart';
import 'document_author_row.dart';

class InventoryCard extends StatelessWidget {
  const InventoryCard({
    super.key,
    required this.document,
    this.onReturnFromDetails,
  });

  final InventoryDocument document;
  final VoidCallback? onReturnFromDetails;

  @override
  Widget build(BuildContext context) {
    final dateLabel = document.dateDisplay ??
        '${document.date.day.toString().padLeft(2, '0')}.'
            '${document.date.month.toString().padLeft(2, '0')}.'
            '${document.date.year}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  InventoryDetailsScreen(inventoryId: document.id),
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
                    Icons.inventory_2_outlined,
                    color: AppColors.deepBrownLight,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${AppStrings.inventoryNumber}${document.number}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(label: AppStrings.date, value: dateLabel),
              const SizedBox(height: 4),
              DocumentCardAuthorRow(
                documentId: document.id,
                authorLogin: document.authorLogin,
                author: document.author,
              ),
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
