import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

class AppNavItem {
  const AppNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

abstract final class AppNavigation {
  static const titles = [
    AppStrings.orders,
    AppStrings.transfers,
    AppStrings.writeoffs,
    AppStrings.inventory,
    AppStrings.production,
  ];

  static const items = [
    AppNavItem(
      label: AppStrings.orders,
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
    ),
    AppNavItem(
      label: AppStrings.transfers,
      icon: Icons.swap_horiz_outlined,
      selectedIcon: Icons.swap_horiz,
    ),
    AppNavItem(
      label: AppStrings.writeoffs,
      icon: Icons.remove_circle_outline,
      selectedIcon: Icons.remove_circle,
    ),
    AppNavItem(
      label: AppStrings.inventory,
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
    ),
    AppNavItem(
      label: AppStrings.production,
      icon: Icons.factory_outlined,
      selectedIcon: Icons.factory,
    ),
  ];
}
