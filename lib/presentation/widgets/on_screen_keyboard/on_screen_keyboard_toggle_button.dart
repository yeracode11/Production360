import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import 'on_screen_keyboard_controller.dart';

class OnScreenKeyboardToggleButton extends StatelessWidget {
  const OnScreenKeyboardToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = sl<OnScreenKeyboardController>();

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final visible = controller.isVisible;
        return IconButton(
          tooltip: visible
              ? AppStrings.onScreenKeyboardHide
              : AppStrings.onScreenKeyboardShow,
          onPressed: controller.toggle,
          icon: Icon(
            visible ? Icons.keyboard_hide : Icons.keyboard,
            color: visible ? AppColors.turquoiseDark : null,
          ),
        );
      },
    );
  }
}
