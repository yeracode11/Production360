import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/enums/order_status.dart';
import '../../../domain/entities/order_request.dart';
import '../../bloc/orders/orders_cubit.dart';
import '../../bloc/orders/orders_state.dart';
import '../../bloc/warehouse/warehouse_cubit.dart';
import '../../bloc/warehouse/warehouse_state.dart';
import '../../widgets/completed_week_filter.dart';
import '../../widgets/order_card.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final warehouseState = context.read<WarehouseCubit>().state;
      final ordersState = context.read<OrdersCubit>().state;
      if (warehouseState is WarehouseLoaded && ordersState is OrdersInitial) {
        context
            .read<OrdersCubit>()
            .loadOrders(warehouseState.selectedWarehouse.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final warehouseCubit = context.read<WarehouseCubit>();
    final ordersCubit = context.read<OrdersCubit>();

    final warehouseState = warehouseCubit.state;
    if (warehouseState is WarehouseLoaded) {
      await ordersCubit.refreshOrders(warehouseState.selectedWarehouse.id);
      return;
    }

    await warehouseCubit.refreshFromApi();
    final refreshedState = warehouseCubit.state;
    if (refreshedState is WarehouseLoaded) {
      await ordersCubit.refreshOrders(refreshedState.selectedWarehouse.id);
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
          context.read<OrdersCubit>().loadOrders(state.selectedWarehouse.id);
        }
      },
      child: Column(
        children: [
          Material(
            color: AppColors.cream,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: AppStrings.pendingConfirmation),
                Tab(text: AppStrings.pendingDelivery),
                Tab(text: AppStrings.completed),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<WarehouseCubit, WarehouseState>(
              builder: (context, warehouseState) {
                if (warehouseState is WarehouseEmpty) {
                  return RefreshIndicator(
                    onRefresh: _onRefresh,
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
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

                return BlocBuilder<OrdersCubit, OrdersState>(
                  builder: (context, state) {
                    if (state is OrdersLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is OrdersFailure) {
                      return RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4,
                              child: Center(
                                child: Text(
                                  state.message,
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is OrdersLoaded) {
                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _RefreshableOrderList(
                            onRefresh: _onRefresh,
                            orders: state.orders
                                .where(
                                  (o) =>
                                      o.status ==
                                      OrderStatus.pendingConfirmation,
                                )
                                .toList(),
                            emptyMessage: AppStrings.noOrders,
                            onReturnFromDetails: () => context
                                .read<OrdersCubit>()
                                .loadOrders(warehouseId),
                          ),
                          _RefreshableOrderList(
                            onRefresh: _onRefresh,
                            orders: state.orders
                                .where(
                                  (o) =>
                                      o.status == OrderStatus.pendingDelivery,
                                )
                                .toList(),
                            emptyMessage: AppStrings.noOrders,
                            onReturnFromDetails: () => context
                                .read<OrdersCubit>()
                                .loadOrders(warehouseId),
                          ),
                          _CompletedOrdersTab(
                            state: state,
                            onRefresh: _onRefresh,
                            warehouseId: warehouseId,
                            onWeekSelected: (date) {
                              context
                                  .read<OrdersCubit>()
                                  .setCompletedWeekFromDate(date);
                            },
                          ),
                        ],
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedOrdersTab extends StatelessWidget {
  const _CompletedOrdersTab({
    required this.state,
    required this.onRefresh,
    required this.warehouseId,
    required this.onWeekSelected,
  });

  final OrdersLoaded state;
  final Future<void> Function() onRefresh;
  final String warehouseId;
  final ValueChanged<DateTime> onWeekSelected;

  @override
  Widget build(BuildContext context) {
    final orders = state.completedOrdersForWeek;
    final hasOtherCompleted =
        orders.isEmpty && state.completedOrdersTotal > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CompletedWeekFilter(
          weekStart: state.completedWeekStart,
          weekEnd: state.completedWeekEnd,
          onWeekSelected: onWeekSelected,
        ),
        Expanded(
          child: _RefreshableOrderList(
            onRefresh: onRefresh,
            orders: orders,
            emptyMessage: hasOtherCompleted
                ? AppStrings.noOrdersForWeek
                : AppStrings.noOrders,
            onReturnFromDetails: () =>
                context.read<OrdersCubit>().loadOrders(warehouseId),
          ),
        ),
      ],
    );
  }
}

class _RefreshableOrderList extends StatelessWidget {
  const _RefreshableOrderList({
    required this.onRefresh,
    required this.orders,
    required this.emptyMessage,
    this.onReturnFromDetails,
  });

  final Future<void> Function() onRefresh;
  final List<OrderRequest> orders;
  final String emptyMessage;
  final VoidCallback? onReturnFromDetails;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35,
              child: Center(
                child: Text(
                  emptyMessage,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.deepBrownLight,
                      ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: orders.length,
        itemBuilder: (context, index) => OrderCard(
          order: orders[index],
          onReturnFromDetails: onReturnFromDetails,
        ),
      ),
    );
  }
}
