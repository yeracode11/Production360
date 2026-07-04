import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/internal_transfer.dart';
import '../screens/transfers/transfer_details_screen.dart';

class TransferCard extends StatelessWidget {
  const TransferCard({super.key, required this.transfer});

  final InternalTransfer transfer;

  @override
  Widget build(BuildContext context) {
    final dateLabel = transfer.dateDisplay ??
        '${transfer.date.day.toString().padLeft(2, '0')}.'
            '${transfer.date.month.toString().padLeft(2, '0')}.'
            '${transfer.date.year}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TransferDetailsScreen(transferId: transfer.id),
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
                  _PostedChip(isPosted: transfer.isPosted),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(label: AppStrings.date, value: dateLabel),
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
        isPosted ? AppStrings.transferPosted : AppStrings.transferNotPosted,
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
