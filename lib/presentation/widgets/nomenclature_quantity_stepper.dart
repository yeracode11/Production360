import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/amount_parser.dart';
import '../../core/utils/quantity_input.dart';

/// Компактный ввод количества: − / поле / +.
class NomenclatureQuantityStepper extends StatefulWidget {
  const NomenclatureQuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    required this.onRemove,
    this.allowZero = false,
  });

  final num quantity;
  final ValueChanged<num> onChanged;
  final VoidCallback onRemove;
  final bool allowZero;

  @override
  State<NomenclatureQuantityStepper> createState() =>
      _NomenclatureQuantityStepperState();
}

class _NomenclatureQuantityStepperState
    extends State<NomenclatureQuantityStepper> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.quantity));
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant NomenclatureQuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity == widget.quantity) return;
    final next = _format(widget.quantity);
    if (_controller.text != next) {
      _controller.text = next;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _format(num value) => formatQuantityForInput(value);

  num _currentQuantity() {
    final parsed = parseAmount(_controller.text);
    if (parsed != null && _isValidQuantity(parsed)) return parsed;
    return widget.quantity;
  }

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

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _applyText(_controller.text);
    }
  }

  void _handleTextChanged(String raw) {
    if (!_isCompleteQuantity(raw)) return;
    final parsed = parseAmount(raw);
    if (!_isValidQuantity(parsed) || parsed == widget.quantity) return;
    widget.onChanged(parsed!);
  }

  void _applyText(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || !_isCompleteQuantity(trimmed)) {
      _controller.text = _format(widget.quantity);
      return;
    }

    final parsed = parseAmount(trimmed);
    if (!_isValidQuantity(parsed)) {
      _controller.text = _format(widget.quantity);
      return;
    }

    if (parsed != widget.quantity) {
      widget.onChanged(parsed!);
    } else {
      _controller.text = _format(parsed!);
    }
  }

  void _decrement() {
    final current = _currentQuantity();

    if (widget.allowZero) {
      if (current <= 0) {
        widget.onRemove();
        return;
      }
      final next = current - 1;
      final resolved = next < 0 ? 0 : next;
      widget.onChanged(resolved);
      _controller.text = _format(resolved);
      return;
    }

    final next = current - 1;
    if (next <= 0) {
      widget.onRemove();
      return;
    }
    widget.onChanged(next);
    _controller.text = _format(next);
  }

  void _increment() {
    final next = _currentQuantity() + 1;
    widget.onChanged(next);
    _controller.text = _format(next);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperIconButton(
          icon: Icons.remove_rounded,
          color: AppColors.error,
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          onPressed: _decrement,
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 56,
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
          ),
        ),
        const SizedBox(width: 4),
        _StepperIconButton(
          icon: Icons.add_rounded,
          color: AppColors.turquoiseDark,
          backgroundColor: AppColors.mintSoft,
          onPressed: _increment,
        ),
      ],
    );
  }
}

class _StepperIconButton extends StatelessWidget {
  const _StepperIconButton({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
