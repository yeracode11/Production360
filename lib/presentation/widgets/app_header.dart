import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import 'warehouse_selector.dart';

/// Global AppBar with menu drawer trigger and warehouse selector.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key, this.title, required this.onMenuPressed});

  final String? title;
  final VoidCallback onMenuPressed;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title != null ? Text(title!) : null,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        tooltip: AppStrings.menu,
        onPressed: onMenuPressed,
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 8),
          child: WarehouseSelector(),
        ),
      ],
    );
  }
}
