import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_features.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/platform_layout.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/warehouse/warehouse_cubit.dart';
import '../../bloc/warehouse/warehouse_state.dart';
import '../../navigation/app_navigation.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_sidebar.dart';
import '../inventory/create_inventory_screen.dart';
import '../inventory/inventory_screen.dart';
import '../production/create_production_screen.dart';
import '../production/production_screen.dart';
import '../orders/select_order_type_screen.dart';
import '../orders/orders_screen.dart';
import '../settings/settings_screen.dart';
import '../transfers/create_transfer_screen.dart';
import '../transfers/transfers_placeholder_screen.dart';
import '../transfers/transfers_screen.dart';
import '../writeoffs/create_writeoff_screen.dart';
import '../writeoffs/writeoffs_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  final _screens = [
    const OrdersScreen(),
    AppFeatures.transfersEnabled
        ? const TransfersScreen()
        : const TransfersPlaceholderScreen(),
    const WriteoffsScreen(),
    const InventoryScreen(),
    const ProductionScreen(),
  ];

  void _setIndex(int index) => setState(() => _currentIndex = index);

  void _logout() {
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

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

  void _openCreateWriteoff(WarehouseLoaded warehouseState) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateWriteoffScreen(
          warehouse: warehouseState.selectedWarehouse,
        ),
      ),
    );
  }

  void _openCreateInventory(WarehouseLoaded warehouseState) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateInventoryScreen(
          warehouse: warehouseState.selectedWarehouse,
        ),
      ),
    );
  }

  void _openCreateProduction(WarehouseLoaded warehouseState) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateProductionScreen(
          warehouse: warehouseState.selectedWarehouse,
        ),
      ),
    );
  }

  void _onCreatePressed(WarehouseLoaded warehouseState) {
    switch (_currentIndex) {
      case 0:
        _openCreateOrder(warehouseState);
      case 1:
        if (AppFeatures.transfersEnabled) {
          _openCreateTransfer(warehouseState);
        }
      case 2:
        _openCreateWriteoff(warehouseState);
      case 3:
        _openCreateInventory(warehouseState);
      case 4:
        _openCreateProduction(warehouseState);
    }
  }

  String? get _createActionLabel {
    switch (_currentIndex) {
      case 0:
        return AppStrings.createOrder;
      case 1:
        return AppFeatures.transfersEnabled ? AppStrings.createTransfer : null;
      case 2:
        return AppStrings.createWriteoff;
      case 3:
        return AppStrings.createInventory;
      case 4:
        return AppStrings.createProduction;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformLayout.useDesktopNavigation(context)) {
      return _buildDesktopShell(context);
    }
    return _buildMobileShell(context);
  }

  Widget _buildDesktopShell(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            currentIndex: _currentIndex,
            onNavigate: _setIndex,
            onLogout: _logout,
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                AppHeader(
                  title: AppNavigation.titles[_currentIndex],
                  showMenuButton: false,
                  showOnScreenKeyboard: true,
                  trailing: _buildCreateAction(desktop: true),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileShell(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppHeader(
        title: AppNavigation.titles[_currentIndex],
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        showOnScreenKeyboard: PlatformLayout.isDesktopPlatform,
      ),
      drawer: _AppDrawer(
        currentIndex: _currentIndex,
        onNavigate: (index) {
          Navigator.pop(context);
          _setIndex(index);
        },
        onLogout: () {
          Navigator.pop(context);
          _logout();
        },
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _setIndex,
        items: [
          for (final item in AppNavigation.items)
            BottomNavigationBarItem(
              icon: Icon(item.icon),
              activeIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      ),
      floatingActionButton: _buildCreateAction(desktop: false),
    );
  }

  Widget? _buildCreateAction({required bool desktop}) {
    final label = _createActionLabel;
    if (label == null) {
      return null;
    }

    return BlocBuilder<WarehouseCubit, WarehouseState>(
      builder: (context, state) {
        if (state is! WarehouseLoaded) {
          return const SizedBox.shrink();
        }

        if (desktop) {
          return FilledButton.icon(
            onPressed: () => _onCreatePressed(state),
            icon: const Icon(Icons.add, size: 18),
            label: Text(label),
          );
        }

        return FloatingActionButton.extended(
          onPressed: () => _onCreatePressed(state),
          icon: const Icon(Icons.add),
          label: Text(label),
        );
      },
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.currentIndex,
    required this.onNavigate,
    required this.onLogout,
  });

  final int currentIndex;
  final ValueChanged<int> onNavigate;
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
            for (var i = 0; i < AppNavigation.items.length; i++)
              _DrawerNavTile(
                item: AppNavigation.items[i],
                selected: currentIndex == i,
                onTap: () => onNavigate(i),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text(AppStrings.profile),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text(AppStrings.settings),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const Spacer(),
            const Divider(height: 1),
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

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        selected ? item.selectedIcon : item.icon,
        color: selected ? AppColors.turquoiseDark : null,
      ),
      title: Text(
        item.label,
        style: selected
            ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.turquoiseDark,
                )
            : null,
      ),
      selected: selected,
      selectedTileColor: AppColors.mintSoft,
      onTap: onTap,
    );
  }
}
