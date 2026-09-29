import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_features.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/repositories/return_repository.dart';
import '../../../core/utils/platform_layout.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/warehouse/warehouse_cubit.dart';
import '../../bloc/warehouse/warehouse_state.dart';
import '../../navigation/app_navigation.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/desktop_content_constraint.dart';
import '../inventory/create_inventory_screen.dart';
import '../production/create_production_screen.dart';
import '../orders/select_order_type_screen.dart';
import '../settings/settings_screen.dart';
import '../transfers/create_transfer_screen.dart';
import '../writeoffs/create_writeoff_screen.dart';
import '../returns/create_return_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  AppModuleId? _selectedModuleId;
  final Set<AppModuleId> _loadedModuleIds = {};

  void _selectModule(AppModuleId moduleId) {
    setState(() {
      _selectedModuleId = moduleId;
      _loadedModuleIds.add(moduleId);
    });
  }

  AppModuleId _resolveSelectedModule(List<AppNavItem> modules) {
    if (modules.isEmpty) {
      return AppModuleId.orders;
    }
    final selected = _selectedModuleId;
    if (selected != null &&
        modules.any((module) => module.moduleId == selected)) {
      return selected;
    }
    return modules.first.moduleId;
  }

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

  void _openCreateReturn(WarehouseLoaded warehouseState) {
    final warehouse = warehouseState.selectedWarehouse;
    final predataFuture = sl<ReturnRepository>().fetchPredata(
      warehouseId: warehouse.id,
    );
    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateReturnScreen(
          warehouse: warehouse,
          predataFuture: predataFuture,
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

  void _onCreatePressed(AppModuleId moduleId, WarehouseLoaded warehouseState) {
    switch (moduleId) {
      case AppModuleId.orders:
        _openCreateOrder(warehouseState);
      case AppModuleId.transfers:
        if (AppFeatures.transfersEnabled) {
          _openCreateTransfer(warehouseState);
        }
      case AppModuleId.writeoffs:
        _openCreateWriteoff(warehouseState);
      case AppModuleId.returns:
        _openCreateReturn(warehouseState);
      case AppModuleId.inventory:
        _openCreateInventory(warehouseState);
      case AppModuleId.production:
        _openCreateProduction(warehouseState);
    }
  }

  String? _createActionLabel(AppModuleId moduleId) {
    switch (moduleId) {
      case AppModuleId.orders:
        return AppStrings.createOrder;
      case AppModuleId.transfers:
        return AppFeatures.transfersEnabled ? AppStrings.createTransfer : null;
      case AppModuleId.writeoffs:
        return AppStrings.createWriteoff;
      case AppModuleId.returns:
        return AppStrings.createReturn;
      case AppModuleId.inventory:
        return AppStrings.createInventory;
      case AppModuleId.production:
        return AppStrings.createProduction;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const SizedBox.shrink();
        }

        final modules = AppNavigation.modulesForUser(authState.user);
        if (modules.isEmpty) {
          return _NoModulesShell(onLogout: _logout);
        }

        final selectedModuleId = _resolveSelectedModule(modules);
        if (_selectedModuleId != selectedModuleId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _selectModule(selectedModuleId);
          });
        }

        _loadedModuleIds.add(selectedModuleId);

        if (PlatformLayout.useDesktopNavigation(context)) {
          return _buildDesktopShell(context, modules, selectedModuleId);
        }
        return _buildMobileShell(context, modules, selectedModuleId);
      },
    );
  }

  List<Widget> _buildLazyScreens(List<AppNavItem> modules) {
    return modules
        .map(
          (module) => _loadedModuleIds.contains(module.moduleId)
              ? AppNavigation.screenForModule(module)
              : const SizedBox.shrink(),
        )
        .toList();
  }

  int _indexOfModule(List<AppNavItem> modules, AppModuleId moduleId) {
    return modules.indexWhere((module) => module.moduleId == moduleId);
  }

  Widget _buildDesktopShell(
    BuildContext context,
    List<AppNavItem> modules,
    AppModuleId selectedModuleId,
  ) {
    final selectedIndex = _indexOfModule(modules, selectedModuleId);
    final selectedModule =
        modules.firstWhere((module) => module.moduleId == selectedModuleId);

    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            modules: modules,
            selectedModuleId: selectedModuleId,
            onNavigate: _selectModule,
            onLogout: _logout,
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                AppHeader(
                  title: selectedModule.label,
                  showMenuButton: false,
                  showOnScreenKeyboard: true,
                  trailing: _buildCreateAction(
                    desktop: true,
                    moduleId: selectedModuleId,
                  ),
                ),
                Expanded(
                  child: DesktopContentConstraint(
                    child: IndexedStack(
                      index: selectedIndex < 0 ? 0 : selectedIndex,
                      children: _buildLazyScreens(modules),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileShell(
    BuildContext context,
    List<AppNavItem> modules,
    AppModuleId selectedModuleId,
  ) {
    final selectedIndex = _indexOfModule(modules, selectedModuleId);
    final selectedModule =
        modules.firstWhere((module) => module.moduleId == selectedModuleId);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppHeader(
        title: selectedModule.label,
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        showOnScreenKeyboard: PlatformLayout.isDesktopPlatform,
      ),
      drawer: _AppDrawer(
        modules: modules,
        selectedModuleId: selectedModuleId,
        onNavigate: (moduleId) {
          Navigator.pop(context);
          _selectModule(moduleId);
        },
        onLogout: () {
          Navigator.pop(context);
          _logout();
        },
      ),
      body: IndexedStack(
        index: selectedIndex < 0 ? 0 : selectedIndex,
        children: _buildLazyScreens(modules),
      ),
      bottomNavigationBar: modules.length <= 1
          ? null
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: selectedIndex < 0 ? 0 : selectedIndex,
              onTap: (index) => _selectModule(modules[index].moduleId),
              items: [
                for (final module in modules)
                  BottomNavigationBarItem(
                    icon: Icon(module.icon),
                    activeIcon: Icon(module.selectedIcon),
                    label: module.label,
                  ),
              ],
            ),
      floatingActionButton: _buildCreateAction(
        desktop: false,
        moduleId: selectedModuleId,
      ),
    );
  }

  Widget? _buildCreateAction({
    required bool desktop,
    required AppModuleId moduleId,
  }) {
    final label = _createActionLabel(moduleId);
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
            onPressed: () => _onCreatePressed(moduleId, state),
            icon: const Icon(Icons.add, size: 18),
            label: Text(label),
          );
        }

        return FloatingActionButton.extended(
          onPressed: () => _onCreatePressed(moduleId, state),
          icon: const Icon(Icons.add),
          label: Text(label),
        );
      },
    );
  }
}

class _NoModulesShell extends StatelessWidget {
  const _NoModulesShell({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 56,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.noAccessibleModules,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
                label: const Text(AppStrings.logout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.modules,
    required this.selectedModuleId,
    required this.onNavigate,
    required this.onLogout,
  });

  final List<AppNavItem> modules;
  final AppModuleId selectedModuleId;
  final ValueChanged<AppModuleId> onNavigate;
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
            for (final module in modules)
              _DrawerNavTile(
                item: module,
                selected: selectedModuleId == module.moduleId,
                onTap: () => onNavigate(module.moduleId),
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
