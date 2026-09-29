import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/transfer_predata.dart';
import '../../widgets/app_bar_with_keyboard.dart';
import '../../widgets/desktop_content_constraint.dart';

/// Полноэкранный выбор склада получателя с поиском.
class SelectRecipientWarehouseScreen extends StatefulWidget {
  const SelectRecipientWarehouseScreen({
    super.key,
    required this.warehouses,
    this.selected,
    this.title = AppStrings.recipientWarehouse,
  });

  final List<TransferWarehouseOption> warehouses;
  final TransferWarehouseOption? selected;
  final String title;

  @override
  State<SelectRecipientWarehouseScreen> createState() =>
      _SelectRecipientWarehouseScreenState();
}

class _SelectRecipientWarehouseScreenState
    extends State<SelectRecipientWarehouseScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransferWarehouseOption> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.warehouses;
    return widget.warehouses
        .where((w) => w.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return Scaffold(
      appBar: AppBarWithKeyboard(title: widget.title),
      body: DesktopContentConstraint(
        child: Column(
          children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: AppStrings.searchWarehouseHint,
                prefixIcon:
                    Icon(Icons.search, color: AppColors.turquoiseDark),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: AppStrings.clearSearch,
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceCard,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.surfaceMuted),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.turquoise,
                    width: 1.5,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final warehouse = results[index];
                      final isSelected = warehouse.id == widget.selected?.id;
                      return _WarehouseTile(
                        warehouse: warehouse,
                        isSelected: isSelected,
                        onTap: () => Navigator.of(context).pop(warehouse),
                      );
                    },
                  ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warehouse_outlined,
              size: 56,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.warehousesNotFound,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarehouseTile extends StatelessWidget {
  const _WarehouseTile({
    required this.warehouse,
    required this.isSelected,
    required this.onTap,
  });

  final TransferWarehouseOption warehouse;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.mintSoft : AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.turquoise : AppColors.surfaceMuted,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.warehouse_outlined,
                  size: 20,
                  color: AppColors.turquoiseDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  warehouse.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle, color: AppColors.turquoise, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
