import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/return_document.dart';
import '../screens/returns/return_details_screen.dart';
import 'document_author_row.dart';

class ReturnCard extends StatelessWidget {
  const ReturnCard({
    super.key,
    required this.returnDocument,
    this.onReturnFromDetails,
  });

  final ReturnDocument returnDocument;
  final VoidCallback? onReturnFromDetails;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  ReturnDetailsScreen(returnId: returnDocument.id),
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
                    Icons.undo_outlined,
                    color: AppColors.deepBrownLight,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${AppStrings.returnNumber}${returnDocument.number}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DocumentCardAuthorRow(
                documentId: returnDocument.id,
                authorLogin: returnDocument.authorLogin,
                author: returnDocument.author,
              ),
              const SizedBox(height: 4),
              _InfoRow(
                label: AppStrings.sender,
                value: returnDocument.senderWarehouseDisplay,
              ),
              if (returnDocument.recipientWarehouseDisplay.isNotEmpty) ...[
                const SizedBox(height: 4),
                _InfoRow(
                  label: AppStrings.recipient,
                  value: returnDocument.recipientWarehouseDisplay,
                ),
              ],
              if (returnDocument.comment != null &&
                  returnDocument.comment!.isNotEmpty) ...[
                const SizedBox(height: 4),
                _InfoRow(
                  label: AppStrings.comment,
                  value: returnDocument.comment!,
                ),
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
