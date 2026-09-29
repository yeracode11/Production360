import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import 'on_screen_keyboard_controller.dart';
import 'on_screen_keyboard_language.dart';
import 'on_screen_keyboard_layouts.dart';
import 'on_screen_keyboard_type.dart';

class OnScreenKeyboardPanel extends StatelessWidget {
  const OnScreenKeyboardPanel({
    super.key,
    required this.controller,
  });

  final OnScreenKeyboardController controller;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      child: Material(
        elevation: 8,
        color: AppColors.surfaceCard,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: controller.inputType == OnScreenKeyboardType.numeric
                ? _NumericKeyboard(controller: controller)
                : _TextKeyboard(controller: controller),
          ),
        ),
      ),
    );
  }
}

class _TextKeyboard extends StatelessWidget {
  const _TextKeyboard({required this.controller});

  final OnScreenKeyboardController controller;

  @override
  Widget build(BuildContext context) {
    final rows = controller.isSymbolsPage
        ? OnScreenKeyboardLayouts.symbolRows()
        : OnScreenKeyboardLayouts.rowsFor(controller.language);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!controller.isSymbolsPage) ...[
          _LanguageSwitcher(controller: controller),
          const SizedBox(height: 6),
        ],
        for (final row in rows) _KeyRow(keys: row, controller: controller),
        const SizedBox(height: 6),
        Row(
          children: [
            if (!controller.isSymbolsPage) ...[
              Expanded(
                flex: 2,
                child: _KeyButton(
                  icon: Icons.keyboard_arrow_up,
                  selected: controller.isShiftActive,
                  onPressed: controller.toggleShift,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              flex: 2,
              child: _KeyButton(
                label: controller.isSymbolsPage
                    ? AppStrings.onScreenKeyboardLetters
                    : AppStrings.onScreenKeyboardSymbols,
                selected: controller.isSymbolsPage,
                onPressed: controller.isSymbolsPage
                    ? controller.showLetters
                    : controller.showSymbols,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 4,
              child: _KeyButton(
                label: AppStrings.onScreenKeyboardSpace,
                onPressed: () => controller.insert(' '),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: _KeyButton(
                icon: Icons.backspace_outlined,
                onPressed: controller.backspace,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: _KeyButton(
                icon: Icons.keyboard_return,
                onPressed: controller.insertNewline,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LanguageSwitcher extends StatelessWidget {
  const _LanguageSwitcher({required this.controller});

  final OnScreenKeyboardController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < OnScreenKeyboardLanguage.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _ToggleKeyButton(
              label: OnScreenKeyboardLanguage.values[i].label,
              selected: controller.language == OnScreenKeyboardLanguage.values[i],
              onPressed: () =>
                  controller.setLanguage(OnScreenKeyboardLanguage.values[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _ToggleKeyButton extends StatelessWidget {
  const _ToggleKeyButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Material(
        color: selected ? AppColors.mintSoft : AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? AppColors.turquoise : AppColors.surfaceMuted,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          canRequestFocus: false,
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppColors.turquoiseDark
                        : AppColors.textSecondary,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NumericKeyboard extends StatelessWidget {
  const _NumericKeyboard({required this.controller});

  final OnScreenKeyboardController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _KeyRow(keys: const ['7', '8', '9'], controller: controller),
        const SizedBox(height: 6),
        _KeyRow(keys: const ['4', '5', '6'], controller: controller),
        const SizedBox(height: 6),
        _KeyRow(keys: const ['1', '2', '3'], controller: controller),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _KeyButton(
                label: ',',
                onPressed: () => controller.insert(','),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _KeyButton(
                label: '0',
                onPressed: () => controller.insert('0'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _KeyButton(
                icon: Icons.backspace_outlined,
                onPressed: controller.backspace,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.keys,
    required this.controller,
  });

  final List<String> keys;
  final OnScreenKeyboardController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          for (var i = 0; i < keys.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: _KeyButton(
                label: controller.displayKey(keys[i]),
                onPressed: () => controller.insert(keys[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    this.label,
    this.icon,
    this.selected = false,
    required this.onPressed,
  });

  final String? label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final child = icon != null
        ? Icon(icon, size: 20, color: AppColors.textPrimary)
        : Text(
            label ?? '',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: label != null && label!.length > 2 ? 14 : null,
                ),
          );

    return SizedBox(
      height: 44,
      child: Material(
        color: selected ? AppColors.mintSoft : AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? AppColors.turquoise : AppColors.surfaceMuted,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          canRequestFocus: false,
          child: Center(child: child),
        ),
      ),
    );
  }
}
