import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/week_range.dart';
import '../../bloc/inventory/inventory_cubit.dart';
import '../../bloc/inventory/inventory_state.dart';
import '../../bloc/warehouse/warehouse_cubit.dart';
import '../../bloc/warehouse/warehouse_state.dart';
import '../../widgets/completed_week_filter.dart';
import '../../widgets/inventory_card.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  Future<void> _onRefresh(BuildContext context) async {
    final warehouseCubit = context.read<WarehouseCubit>();
    final inventoryCubit = context.read<InventoryCubit>();

    await warehouseCubit.refreshFromApi();
    final warehouseState = warehouseCubit.state;
    if (warehouseState is WarehouseLoaded) {
      await inventoryCubit
          .refreshInventories(warehouseState.selectedWarehouse.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WarehouseCubit, WarehouseState>(
      listenWhen: (previous, current) {
        if (current is! WarehouseLoaded) return false;
        if (previous is! WarehouseLoaded) return true;
        return previous.selectedWarehouse.id != current.selectedWarehouse.id;
      },
      listener: (context, state) {
        if (state is WarehouseLoaded) {
          context
              .read<InventoryCubit>()
              .loadInventories(state.selectedWarehouse.id);
        }
      },
      child: BlocBuilder<WarehouseCubit, WarehouseState>(
        builder: (context, warehouseState) {
          if (warehouseState is WarehouseEmpty) {
            return RefreshIndicator(
              onRefresh: () => _onRefresh(context),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          AppStrings.noWarehouses,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.deepBrownLight,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (warehouseState is! WarehouseLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final warehouseId = warehouseState.selectedWarehouse.id;

          return BlocBuilder<InventoryCubit, InventoryState>(
            builder: (context, state) {
              if (state is InventoryInitial) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.read<InventoryCubit>().loadInventories(warehouseId);
                });
              }

              final week = state is InventoryLoaded
                  ? WeekRange(start: state.weekStart, end: state.weekEnd)
                  : WeekRange.current();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CompletedWeekFilter(
                    weekStart: week.start,
                    weekEnd: week.end,
                    onWeekSelected: (date) {
                      context.read<InventoryCubit>().setWeekFromDate(
                            date,
                            warehouseId,
                          );
                    },
                  ),
                  if (state is InventoryLoading)
                    const LinearProgressIndicator(minHeight: 2),
                  Expanded(child: _buildBody(context, state, warehouseId)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    InventoryState state,
    String warehouseId,
  ) {
    if (state is InventoryLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is InventoryFailure) {
      return RefreshIndicator(
        onRefresh: () => _onRefresh(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state is! InventoryLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final documents = state.documentsForWeek;

    if (documents.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _onRefresh(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    AppStrings.noInventoriesForWeek,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _onRefresh(context),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: documents.length,
        itemBuilder: (context, index) {
          return InventoryCard(
            document: documents[index],
            onReturnFromDetails: () =>
                context.read<InventoryCubit>().loadInventories(warehouseId),
          );
        },
      ),
    );
  }
}
