import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_features.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/warehouse/warehouse_cubit.dart';
import '../../widgets/app_header.dart';
import '../inventory/inventory_screen.dart';
import '../orders/select_order_type_screen.dart';
import '../orders/orders_screen.dart';
import '../transfers/create_transfer_screen.dart';
import '../transfers/transfers_placeholder_screen.dart';
import '../transfers/transfers_screen.dart';
import '../../bloc/warehouse/warehouse_state.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  static const _titles = [
    AppStrings.orders,
    AppStrings.transfers,
    AppStrings.inventory,
  ];

  final _screens = [
    const OrdersScreen(),
    AppFeatures.transfersEnabled
        ? const TransfersScreen()
        : const TransfersPlaceholderScreen(),
    const InventoryScreen(),
  ];

  void _openCreateOrder(WarehouseLoaded warehouseState) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SelectOrderTypeScreen(
          warehouse: warehouseState.selectedWarehouse,
        ),
      ),
    );
  }

  void _openCreateTransfer(WarehouseLoaded warehouseState) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateTransferScreen(
          warehouse: warehouseState.selectedWarehouse,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppHeader(
        title: _titles[_currentIndex],
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: _AppDrawer(
        onLogout: () {
          Navigator.pop(context);
          context.read<AuthBloc>().add(const AuthLogoutRequested());
        },
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: AppStrings.orders,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz_outlined),
            activeIcon: Icon(Icons.swap_horiz),
            label: AppStrings.transfers,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: AppStrings.inventory,
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? BlocBuilder<WarehouseCubit, WarehouseState>(
              builder: (context, state) {
                if (state is! WarehouseLoaded) return const SizedBox.shrink();
                return FloatingActionButton.extended(
                  onPressed: () => _openCreateOrder(state),
                  icon: const Icon(Icons.add),
                  label: const Text(AppStrings.createOrder),
                );
              },
            )
          : _currentIndex == 1 && AppFeatures.transfersEnabled
              ? BlocBuilder<WarehouseCubit, WarehouseState>(
                  builder: (context, state) {
                    if (state is! WarehouseLoaded) {
                      return const SizedBox.shrink();
                    }
                    return FloatingActionButton.extended(
                      onPressed: () => _openCreateTransfer(state),
                      icon: const Icon(Icons.add),
                      label: const Text(AppStrings.createTransfer),
                    );
                  },
                )
              : null,
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.appName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      if (state is AuthAuthenticated) {
                        return Text(
                          state.user.username,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text(AppStrings.profile),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text(AppStrings.settings),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: AppColors.error),
            title: Text(
              AppStrings.logout,
              style: TextStyle(color: AppColors.error),
            ),
            onTap: onLogout,
          ),
          ],
        ),
      ),
    );
  }
}
