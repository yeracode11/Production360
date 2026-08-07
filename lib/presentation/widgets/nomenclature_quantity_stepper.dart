import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/amount_parser.dart';
import '../../core/utils/platform_layout.dart';
import '../../core/utils/quantity_input.dart';
import 'on_screen_keyboard/on_screen_keyboard_controller.dart';
import 'on_screen_keyboard/on_screen_keyboard_registry.dart';
import 'on_screen_keyboard/on_screen_keyboard_type.dart';

/// Поле ввода количества товара.
class NomenclatureQuantityStepper extends StatefulWidget {
  const NomenclatureQuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    required this.onRemove,
    this.allowZero = false,
    this.allowEmpty = false,
  });

  final num? quantity;
  final ValueChanged<num?> onChanged;
  final VoidCallback onRemove;
  final bool allowZero;
  final bool allowEmpty;

  @override
  State<NomenclatureQuantityStepper> createState() =>
      _NomenclatureQuantityStepperState();
}

class _NomenclatureQuantityStepperState
    extends State<NomenclatureQuantityStepper> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  late final VoidCallback _attachFocusedHandler;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _initialText());
    _focusNode.addListener(_handleFocusChange);
    _attachFocusedHandler = _attachIfFocused;
    OnScreenKeyboardRegistry.register(_attachFocusedHandler);
  }

  @override
  void didUpdateWidget(covariant NomenclatureQuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity == widget.quantity) return;
    final next = _initialText();
    if (_controller.text != next) {
      _controller.text = next;
    }
  }

  @override
  void dispose() {
    OnScreenKeyboardRegistry.unregister(_attachFocusedHandler);
    _focusNode.removeListener(_handleFocusChange);
    sl<OnScreenKeyboardController>().detach(_controller);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _attachActiveField() {
    if (!PlatformLayout.isDesktopPlatform) {
      return;
    }
    final keyboard = sl<OnScreenKeyboardController>();
    if (!keyboard.isVisible) {
      return;
    }
    keyboard.attach(
      _controller,
      type: OnScreenKeyboardType.numeric,
      onChanged: _handleTextChanged,
    );
  }

  void _attachIfFocused() {
    if (!_focusNode.hasFocus) {
      return;
    }
    _attachActiveField();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _attachIfFocused();
      return;
    }

    _applyText(_controller.text);
    if (!sl<OnScreenKeyboardController>().isVisible) {
      sl<OnScreenKeyboardController>().detach(_controller);
    }
  }

  String _format(num value) => formatQuantityForInput(value);

  String _initialText() =>
      widget.quantity == null ? '' : _format(widget.quantity!);

  bool _isCompleteQuantity(String text) {
    return validateQuantityInput(
          text,
          required: true,
          allowZero: widget.allowZero,
        ) ==
        null;
  }

  bool _isValidQuantity(num? parsed) {
    if (parsed == null || parsed < 0) return false;
    if (parsed == 0) return widget.allowZero;
    return true;
  }

  void _commitQuantity(num parsed) {
    if (parsed == 0 && !widget.allowZero) {
      widget.onRemove();
      return;
    }
    if (parsed != widget.quantity) {
      widget.onChanged(parsed);
    }
  }

  void _handleTextChanged(String raw) {
    if (!_isCompleteQuantity(raw)) return;
    final parsed = parseAmount(raw);
    if (!_isValidQuantity(parsed) || parsed == widget.quantity) return;
    _commitQuantity(parsed!);
  }

  void _handleRawEmptyOnBlur() {
    if (widget.allowEmpty) {
      widget.onChanged(null);
      return;
    }
    _controller.text =
        widget.quantity == null ? '' : _format(widget.quantity!);
  }

  void _applyText(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      _handleRawEmptyOnBlur();
      return;
    }
    if (!_isCompleteQuantity(trimmed)) {
      _handleRawEmptyOnBlur();
      return;
    }

    final parsed = parseAmount(trimmed);
    if (parsed == 0 && !widget.allowZero) {
      widget.onRemove();
      return;
    }
    if (!_isValidQuantity(parsed)) {
      _handleRawEmptyOnBlur();
      return;
    }

    if (parsed != widget.quantity) {
      widget.onChanged(parsed!);
    } else {
      _controller.text = _format(parsed!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = sl<OnScreenKeyboardController>();

    return SizedBox(
      width: 72,
      height: 36,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: const [QuantityInputFormatter()],
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          filled: true,
          fillColor: AppColors.surfaceCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.surfaceMuted),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.surfaceMuted),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.turquoise),
          ),
        ),
        onChanged: _handleTextChanged,
        onSubmitted: _applyText,
        onEditingComplete: () => _applyText(_controller.text),
        onTap: () {
          if (PlatformLayout.isDesktopPlatform && keyboard.isVisible) {
            _attachActiveField();
          }
        },
      ),
    );
  }
}
