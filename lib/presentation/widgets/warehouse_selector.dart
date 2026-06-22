import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/warehouse.dart';
import '../bloc/warehouse/warehouse_cubit.dart';
import '../bloc/warehouse/warehouse_state.dart';

/// Compact warehouse selector in the AppBar (1C «Склады»).
class WarehouseSelector extends StatelessWidget {
  const WarehouseSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WarehouseCubit, WarehouseState>(
      builder: (context, state) {
        if (state is WarehouseLoaded) {
          return _CompactSelector(
            warehouses: state.warehouses,
            selected: state.selectedWarehouse,
            onSelected: (warehouse) {
              context.read<WarehouseCubit>().selectWarehouse(warehouse);
            },
          );
        }

        if (state is WarehouseLoading) {
          return const Padding(
            padding: EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (state is WarehouseFailure) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(Icons.error_outline, color: AppColors.error, size: 22),
          );
        }

        if (state is WarehouseEmpty) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              AppStrings.noWarehouses,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _CompactSelector extends StatelessWidget {
  const _CompactSelector({
    required this.warehouses,
    required this.selected,
    required this.onSelected,
  });

  final List<Warehouse> warehouses;
  final Warehouse selected;
  final ValueChanged<Warehouse> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Warehouse>(
      tooltip: '${AppStrings.retailOutlets}: ${selected.name}',
      padding: EdgeInsets.zero,
      offset: const Offset(0, 44),
      onSelected: onSelected,
      itemBuilder: (context) => warehouses
          .map(
            (warehouse) => PopupMenuItem<Warehouse>(
              value: warehouse,
              height: 44,
              child: Text(
                warehouse.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: warehouse.id == selected.id ? FontWeight.w600 : null,
                  color: warehouse.id == selected.id ? AppColors.turquoiseDark : null,
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 155),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceMuted),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_outlined, size: 20, color: AppColors.turquoiseDark),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                selected.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
