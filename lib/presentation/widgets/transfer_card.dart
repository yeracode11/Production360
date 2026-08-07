import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/internal_transfer.dart';
import '../screens/transfers/transfer_details_screen.dart';
import 'document_author_row.dart';

class TransferCard extends StatelessWidget {
  const TransferCard({
    super.key,
    required this.transfer,
    this.onReturnFromDetails,
  });

  final InternalTransfer transfer;
  final VoidCallback? onReturnFromDetails;

  @override
  Widget build(BuildContext context) {
    final dateLabel = transfer.dateDisplay ??
        '${transfer.date.day.toString().padLeft(2, '0')}.'
            '${transfer.date.month.toString().padLeft(2, '0')}.'
            '${transfer.date.year}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TransferDetailsScreen(transferId: transfer.id),
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
                    Icons.swap_horiz,
                    color: AppColors.deepBrownLight,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${AppStrings.transferNumber}${transfer.number}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(label: AppStrings.date, value: dateLabel),
              const SizedBox(height: 4),
              DocumentCardAuthorRow(
                documentId: transfer.id,
                authorLogin: transfer.authorLogin,
                author: transfer.author,
              ),
              const SizedBox(height: 4),
              _InfoRow(
                label: AppStrings.warehouseSender,
                value: transfer.senderWarehouseName,
              ),
              const SizedBox(height: 4),
              _InfoRow(
                label: AppStrings.recipientWarehouse,
                value: transfer.recipientWarehouseName,
              ),
              if (transfer.comment != null) ...[
                const SizedBox(height: 4),
                _InfoRow(label: AppStrings.comment, value: transfer.comment!),
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
