import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import 'warehouse_selector.dart';
import 'on_screen_keyboard/on_screen_keyboard_toggle_button.dart';

/// Global AppBar with optional menu drawer trigger and warehouse selector.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.title,
    this.onMenuPressed,
    this.showMenuButton = true,
    this.showOnScreenKeyboard = false,
    this.trailing,
  });

  final String? title;
  final VoidCallback? onMenuPressed;
  final bool showMenuButton;
  final bool showOnScreenKeyboard;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title != null ? Text(title!) : null,
      leading: showMenuButton
          ? IconButton(
              icon: const Icon(Icons.menu),
              tooltip: AppStrings.menu,
              onPressed: onMenuPressed,
            )
          : null,
      automaticallyImplyLeading: showMenuButton,
      actions: [
        if (showOnScreenKeyboard) const OnScreenKeyboardToggleButton(),
        if (trailing != null) ...[
          trailing!,
          const SizedBox(width: 8),
        ],
        const Padding(
          padding: EdgeInsets.only(right: 8),
          child: WarehouseSelector(),
        ),
      ],
    );
  }
}
