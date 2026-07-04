import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/week_range.dart';
import '../../bloc/transfers/transfers_cubit.dart';
import '../../bloc/transfers/transfers_state.dart';
import '../../bloc/warehouse/warehouse_cubit.dart';
import '../../bloc/warehouse/warehouse_state.dart';
import '../../widgets/completed_week_filter.dart';
import '../../widgets/transfer_card.dart';

class TransfersScreen extends StatelessWidget {
  const TransfersScreen({super.key});

  Future<void> _onRefresh(BuildContext context) async {
    final warehouseCubit = context.read<WarehouseCubit>();
    final transfersCubit = context.read<TransfersCubit>();

    await warehouseCubit.refreshFromApi();
    final warehouseState = warehouseCubit.state;
    if (warehouseState is WarehouseLoaded) {
      await transfersCubit.refreshTransfers(warehouseState.selectedWarehouse.id);
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
          context.read<TransfersCubit>().loadTransfers(state.selectedWarehouse.id);
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

          return BlocBuilder<TransfersCubit, TransfersState>(
            builder: (context, state) {
              if (state is TransfersInitial) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.read<TransfersCubit>().loadTransfers(warehouseId);
                });
              }

              final week = state is TransfersLoaded
                  ? WeekRange(start: state.weekStart, end: state.weekEnd)
                  : WeekRange.current();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CompletedWeekFilter(
                    weekStart: week.start,
                    weekEnd: week.end,
                    onWeekSelected: (date) {
                      context.read<TransfersCubit>().setWeekFromDate(
                            date,
                            warehouseId,
                          );
                    },
                  ),
                  if (state is TransfersLoading)
                    const LinearProgressIndicator(minHeight: 2),
                  Expanded(child: _buildBody(context, state)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, TransfersState state) {
    if (state is TransfersLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is TransfersFailure) {
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

    if (state is! TransfersLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final transfers = state.transfersForWeek;

    if (transfers.isEmpty) {
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
                    AppStrings.noTransfersForWeek,
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
        itemCount: transfers.length,
        itemBuilder: (context, index) {
          return TransferCard(transfer: transfers[index]);
        },
      ),
    );
  }
}
