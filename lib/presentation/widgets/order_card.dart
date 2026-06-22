import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/order_request.dart';
import '../screens/orders/order_details_screen.dart';

/// Card displaying order summary in list views.
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});

  final OrderRequest order;

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${order.deliveryDate.day.toString().padLeft(2, '0')}.${order.deliveryDate.month.toString().padLeft(2, '0')}.${order.deliveryDate.year}';
    final shipmentDateLabel = order.deliveryDateDisplay ??
        '$formattedDate ${order.deliveryDate.hour.toString().padLeft(2, '0')}:${order.deliveryDate.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => OrderDetailsScreen(orderId: order.id),
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
                  Icon(Icons.receipt_long, color: AppColors.deepBrownLight, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${AppStrings.orderId}${order.orderNumber}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _StatusChip(statusLabel: order.displayStatus),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: AppStrings.deliveryDate,
                value: formattedDate,
              ),
              if (order.orderType != null) ...[
                const SizedBox(height: 4),
                _InfoRow(
                  label: AppStrings.orderType,
                  value: order.orderType!,
                ),
              ],
              const SizedBox(height: 4),
              _InfoRow(
                label: AppStrings.shipmentDate,
                value: shipmentDateLabel,
              ),
              if (order.items.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${order.items.length} поз.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.deepBrownLight,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.statusLabel});

  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.mintSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusLabel,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.turquoiseDark,
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
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.deepBrownLight,
              ),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
