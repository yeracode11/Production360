import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/app_bar_with_keyboard.dart';
import '../../widgets/receipt_preview_item.dart';
import '../../widgets/receipt_preview_item_row.dart';

class ReceiptPreviewScreen extends StatelessWidget {
  const ReceiptPreviewScreen({
    super.key,
    required this.items,
    this.orderNumber,
  });

  final List<ReceiptPreviewItem> items;
  final String? orderNumber;

  @override
  Widget build(BuildContext context) {
    final summary = buildReceiptPreviewSummary(items);

    return Scaffold(
      appBar: AppBarWithKeyboard(
        titleWidget: Text(
          orderNumber != null
              ? '${AppStrings.receiptPreviewTitle} № $orderNumber'
              : AppStrings.receiptPreviewTitle,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              summary,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.turquoiseDark,
                  ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return ReceiptPreviewItemRow(item: items[index]);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.close),
            ),
          ),
        ),
      ),
    );
  }
}

/// Открывает полноэкранный предпросмотр приёмки.
Future<void> openReceiptPreviewScreen(
  BuildContext context, {
  required List<ReceiptPreviewItem> items,
  String? orderNumber,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => ReceiptPreviewScreen(
        items: items,
        orderNumber: orderNumber,
      ),
    ),
  );
}
