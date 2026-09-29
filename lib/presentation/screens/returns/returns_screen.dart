import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/week_range.dart';
import '../../bloc/returns/returns_cubit.dart';
import '../../bloc/returns/returns_state.dart';
import '../../bloc/warehouse/warehouse_cubit.dart';
import '../../bloc/warehouse/warehouse_state.dart';
import '../../widgets/completed_week_filter.dart';
import '../../widgets/return_card.dart';

class ReturnsScreen extends StatelessWidget {
  const ReturnsScreen({super.key});

  Future<void> _onRefresh(BuildContext context) async {
    final warehouseCubit = context.read<WarehouseCubit>();
    final returnsCubit = context.read<ReturnsCubit>();

    await warehouseCubit.refreshFromApi();
    final warehouseState = warehouseCubit.state;
    if (warehouseState is WarehouseLoaded) {
      await returnsCubit.refreshReturns(warehouseState.selectedWarehouse.id);
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
          context.read<ReturnsCubit>().loadReturns(state.selectedWarehouse.id);
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

          return BlocBuilder<ReturnsCubit, ReturnsState>(
            builder: (context, state) {
              if (state is ReturnsInitial) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.read<ReturnsCubit>().loadReturns(warehouseId);
                });
              }

              final week = state is ReturnsLoaded
                  ? WeekRange(start: state.weekStart, end: state.weekEnd)
                  : WeekRange.current();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CompletedWeekFilter(
                    weekStart: week.start,
                    weekEnd: week.end,
                    onWeekSelected: (date) {
                      context.read<ReturnsCubit>().setWeekFromDate(
                            date,
                            warehouseId,
                          );
                    },
                  ),
                  if (state is ReturnsLoading)
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
    ReturnsState state,
    String warehouseId,
  ) {
    if (state is ReturnsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ReturnsFailure) {
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

    if (state is! ReturnsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final returns = state.returnsForWeek;

    if (returns.isEmpty) {
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
                    AppStrings.noReturnsForWeek,
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
        itemCount: returns.length,
        itemBuilder: (context, index) {
          return ReturnCard(
            returnDocument: returns[index],
            onReturnFromDetails: () =>
                context.read<ReturnsCubit>().loadReturns(warehouseId),
          );
        },
      ),
    );
  }
}
