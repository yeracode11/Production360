import 'package:flutter/material.dart';

import '../../core/utils/platform_layout.dart';
import 'on_screen_keyboard/on_screen_keyboard_toggle_button.dart';

/// AppBar с кнопкой экранной клавиатуры на desktop.
class AppBarWithKeyboard extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWithKeyboard({
    super.key,
    this.title,
    this.titleWidget,
    this.actions = const [],
    this.bottom,
    this.leading,
    this.automaticallyImplyLeading,
  });

  final String? title;
  final Widget? titleWidget;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final bool? automaticallyImplyLeading;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading ?? true,
      title: titleWidget ?? (title != null ? Text(title!) : null),
      actions: [
        if (PlatformLayout.isDesktopPlatform) const OnScreenKeyboardToggleButton(),
        ...actions,
      ],
      bottom: bottom,
    );
  }
}

/// Добавляет кнопку клавиатуры к actions существующего AppBar.
List<Widget> withKeyboardActions(List<Widget> actions) {
  if (!PlatformLayout.isDesktopPlatform) {
    return actions;
  }
  return [const OnScreenKeyboardToggleButton(), ...actions];
}
