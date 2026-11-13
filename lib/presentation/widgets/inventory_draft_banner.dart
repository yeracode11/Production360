import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/di/injection.dart';
import '../../core/storage/inventory_draft_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/warehouse.dart';
import '../screens/inventory/create_inventory_screen.dart';
import 'confirm_action_dialog.dart';

/// Карточка «Черновик инвентаризации» для выбранного склада.
/// Не отображается, если черновика нет.
class InventoryDraftBanner extends StatelessWidget {
  const InventoryDraftBanner({super.key, required this.warehouse});

  final Warehouse warehouse;

  static String _formatSavedAt(DateTime value) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(value.day)}.${two(value.month)} '
        '${two(value.hour)}:${two(value.minute)}';
  }

  Future<void> _open(BuildContext context) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateInventoryScreen(warehouse: warehouse),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showConfirmActionDialog(
      context,
      title: AppStrings.confirmDeleteInventoryDraft,
    );
    if (!confirmed) return;
    await sl<InventoryDraftStorage>().delete(warehouse.id);
  }

  @override
  Widget build(BuildContext context) {
    final storage = sl<InventoryDraftStorage>();
    return ValueListenableBuilder<int>(
      valueListenable: storage.changes,
      builder: (context, _, _) {
        final draft = storage.read(warehouse.id);
        if (draft == null) return const SizedBox.shrink();

        final theme = Theme.of(context);
        return Card(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.turquoiseDark, width: 1.2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _open(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
              child: Row(
                children: [
                  Icon(Icons.edit_note, color: AppColors.turquoiseDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.inventoryDraft,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.inventoryDraftSummary(
                            draft.items.length,
                            _formatSavedAt(draft.savedAt),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _open(context),
                    child: const Text(AppStrings.inventoryDraftContinue),
                  ),
                  IconButton(
                    tooltip: AppStrings.inventoryDraftDelete,
                    icon: Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () => _delete(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
