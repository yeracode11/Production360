import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/utils/platform_layout.dart';
import 'on_screen_keyboard/on_screen_keyboard_controller.dart';

/// Скрывает клавиатуру при тапе вне активного поля ввода.
class DismissKeyboard extends StatelessWidget {
  const DismissKeyboard({super.key, required this.child});

  final Widget child;

  static void unfocus(BuildContext context) {
    if (PlatformLayout.isDesktopPlatform &&
        sl<OnScreenKeyboardController>().isVisible) {
      return;
    }

    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      currentFocus.unfocus();
    }
  }

  /// Оборачивает область: тап вне поля ввода скрывает клавиатуру.
  static Widget onTap(BuildContext context, Widget child) {
    return GestureDetector(
      onTap: () => unfocus(context),
      behavior: HitTestBehavior.deferToChild,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => unfocus(context),
      behavior: HitTestBehavior.deferToChild,
      child: child,
    );
  }
}
