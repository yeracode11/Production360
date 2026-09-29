import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/utils/platform_layout.dart';
import 'on_screen_keyboard_controller.dart';
import 'on_screen_keyboard_panel.dart';

/// Глобальная панель экранной клавиатуры (desktop) для всех экранов.
class OnScreenKeyboardHost extends StatelessWidget {
  const OnScreenKeyboardHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!PlatformLayout.isDesktopPlatform) {
      return child;
    }

    final keyboard = sl<OnScreenKeyboardController>();

    return Column(
      children: [
        Expanded(child: child),
        ListenableBuilder(
          listenable: keyboard,
          builder: (context, _) {
            if (!keyboard.isVisible) {
              return const SizedBox.shrink();
            }
            return OnScreenKeyboardPanel(controller: keyboard);
          },
        ),
      ],
    );
  }
}
