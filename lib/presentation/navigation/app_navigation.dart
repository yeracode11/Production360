import 'package:flutter/material.dart';

import '../../core/auth/mobile_role_keys.dart';
import '../../core/config/app_features.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/entities/user.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/production/production_screen.dart';
import '../screens/returns/returns_screen.dart';
import '../screens/transfers/transfers_placeholder_screen.dart';
import '../screens/transfers/transfers_screen.dart';
import '../screens/writeoffs/writeoffs_screen.dart';

enum AppModuleId {
  orders,
  transfers,
  writeoffs,
  returns,
  inventory,
  production,
}

class AppNavItem {
  const AppNavItem({
    required this.moduleId,
    required this.roleKey,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });

  final AppModuleId moduleId;
  final String roleKey;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
}

abstract final class AppNavigation {
  static const _allModules = [
    AppNavItem(
      moduleId: AppModuleId.orders,
      roleKey: MobileRoleKeys.orders,
      label: AppStrings.orders,
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
      screen: OrdersScreen(),
    ),
    AppNavItem(
      moduleId: AppModuleId.transfers,
      roleKey: MobileRoleKeys.transfers,
      label: AppStrings.transfers,
      icon: Icons.swap_horiz_outlined,
      selectedIcon: Icons.swap_horiz,
      screen: TransfersScreen(),
    ),
    AppNavItem(
      moduleId: AppModuleId.writeoffs,
      roleKey: MobileRoleKeys.writeoffs,
      label: AppStrings.writeoffs,
      icon: Icons.remove_circle_outline,
      selectedIcon: Icons.remove_circle,
      screen: WriteoffsScreen(),
    ),
    AppNavItem(
      moduleId: AppModuleId.returns,
      roleKey: MobileRoleKeys.returns,
      label: AppStrings.returns,
      icon: Icons.undo_outlined,
      selectedIcon: Icons.undo,
      screen: ReturnsScreen(),
    ),
    AppNavItem(
      moduleId: AppModuleId.inventory,
      roleKey: MobileRoleKeys.inventory,
      label: AppStrings.inventory,
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      screen: InventoryScreen(),
    ),
    AppNavItem(
      moduleId: AppModuleId.production,
      roleKey: MobileRoleKeys.production,
      label: AppStrings.production,
      icon: Icons.factory_outlined,
      selectedIcon: Icons.factory,
      screen: ProductionScreen(),
    ),
  ];

  static List<AppNavItem> modulesForUser(User user) {
    return _allModules.where((module) => _isModuleVisible(module, user)).toList();
  }

  static bool _isModuleVisible(AppNavItem module, User user) {
    if (module.moduleId == AppModuleId.transfers &&
        !AppFeatures.transfersEnabled) {
      return false;
    }
    return user.canAccessRole(module.roleKey);
  }

  static Widget screenForModule(AppNavItem module) {
    if (module.moduleId == AppModuleId.transfers &&
        !AppFeatures.transfersEnabled) {
      return const TransfersPlaceholderScreen();
    }
    return module.screen;
  }

}
