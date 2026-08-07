import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../navigation/app_navigation.dart';
import '../screens/settings/settings_screen.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
    required this.onLogout,
  });

  final int currentIndex;
  final ValueChanged<int> onNavigate;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      child: SizedBox(
        width: 260,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
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
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
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
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (var i = 0; i < AppNavigation.items.length; i++)
                      _SidebarNavTile(
                        item: AppNavigation.items[i],
                        selected: currentIndex == i,
                        onTap: () => onNavigate(i),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text(AppStrings.settings),
                onTap: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: AppColors.error),
                title: Text(
                  AppStrings.logout,
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: onLogout,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarNavTile extends StatelessWidget {
  const _SidebarNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          selected ? item.selectedIcon : item.icon,
          color: selected ? AppColors.turquoiseDark : AppColors.textSecondary,
        ),
        title: Text(
          item.label,
          style: selected
              ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.turquoiseDark,
                  )
              : Theme.of(context).textTheme.bodyLarge,
        ),
        selected: selected,
        selectedTileColor: AppColors.mintSoft,
        onTap: onTap,
      ),
    );
  }
}
