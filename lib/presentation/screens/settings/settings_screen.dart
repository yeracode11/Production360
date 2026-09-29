import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/app_bar_with_keyboard.dart';
import '../../widgets/desktop_content_constraint.dart';
import 'printer_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithKeyboard(title: AppStrings.settings),
      body: DesktopContentConstraint(
        child: ListView(
          children: [
          ListTile(
            leading: const Icon(Icons.print_outlined),
            title: const Text(AppStrings.printerSettings),
            subtitle: Text(
              AppStrings.printerSettingsHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => const PrinterSettingsScreen(),
                ),
              );
            },
          ),
        ],
        ),
      ),
    );
  }
}
