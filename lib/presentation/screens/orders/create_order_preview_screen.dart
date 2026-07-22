import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/accompanying_product_label.dart';
import '../../widgets/document_author_row.dart';
import '../../widgets/order_create_preview_item.dart';
import '../../widgets/order_create_preview_item_row.dart';

class CreateOrderPreviewData {
  const CreateOrderPreviewData({
    required this.warehouseName,
    required this.orderTypeName,
    this.orderTypeForInfo = false,
    required this.organizationName,
    required this.supplierWarehouseName,
    required this.deliveryDate,
    required this.items,
    this.comment,
  });

  final String warehouseName;
  final String orderTypeName;
  final bool orderTypeForInfo;
  final String organizationName;
  final String supplierWarehouseName;
  final String deliveryDate;
  final String? comment;
  final List<OrderCreatePreviewItem> items;
}

class CreateOrderPreviewScreen extends StatelessWidget {
  const CreateOrderPreviewScreen({super.key, required this.data});

  final CreateOrderPreviewData data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.createOrderPreviewTitle),
      ),
      body: CreateOrderPreviewContent(data: data),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    foregroundColor: AppColors.turquoiseDark,
                    side: const BorderSide(
                      color: AppColors.turquoise,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text(AppStrings.close),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    backgroundColor: AppColors.turquoiseDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text(AppStrings.createOrderAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateOrderPreviewContent extends StatelessWidget {
  const CreateOrderPreviewContent({super.key, required this.data});

  final CreateOrderPreviewData data;

  @override
  Widget build(BuildContext context) {
    final summary = buildCreateOrderPreviewSummary(data.items.length);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.mainInfo,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _InfoLine(
                  label: AppStrings.customer,
                  value: data.warehouseName,
                ),
                _InfoLine(
                  label: AppStrings.orderType,
                  value: data.orderTypeName,
                ),
                if (data.orderTypeForInfo) ...[
                  const SizedBox(height: 6),
                  const AccompanyingProductLabel(),
                ],
                _InfoLine(
                  label: AppStrings.organization,
                  value: data.organizationName,
                ),
                _InfoLine(
                  label: AppStrings.warehouse,
                  value: data.supplierWarehouseName,
                ),
                _InfoLine(
                  label: AppStrings.shipmentDate,
                  value: data.deliveryDate,
                ),
                if (data.comment != null && data.comment!.isNotEmpty)
                  _InfoLine(
                    label: AppStrings.comment,
                    value: data.comment!,
                  ),
                const DocumentAuthorPreviewLine(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          summary,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.turquoiseDark,
              ),
        ),
        const SizedBox(height: 10),
        ...List.generate(data.items.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == data.items.length - 1 ? 0 : 10,
            ),
            child: OrderCreatePreviewItemRow(item: data.items[index]),
          );
        }),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool?> openCreateOrderPreviewScreen(
  BuildContext context, {
  required CreateOrderPreviewData data,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      fullscreenDialog: true,
      builder: (context) => CreateOrderPreviewScreen(data: data),
    ),
  );
}
