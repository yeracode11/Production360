import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../core/di/injection.dart';
import '../../../core/utils/platform_layout.dart';
import 'on_screen_keyboard_controller.dart';
import 'on_screen_keyboard_registry.dart';
import 'on_screen_keyboard_type.dart';

OnScreenKeyboardType keyboardTypeFromInput(TextInputType? keyboardType) {
  if (keyboardType == null) {
    return OnScreenKeyboardType.text;
  }
  if (keyboardType == TextInputType.number ||
      keyboardType == TextInputType.phone ||
      keyboardType == const TextInputType.numberWithOptions(decimal: true) ||
      keyboardType == const TextInputType.numberWithOptions(signed: true) ||
      keyboardType ==
          const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          )) {
    return OnScreenKeyboardType.numeric;
  }
  return OnScreenKeyboardType.text;
}

class OnScreenKeyboardTextField extends StatefulWidget {
  const OnScreenKeyboardTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.decoration,
    this.keyboardType,
    this.textInputAction,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.primaryOnScreenKeyboard = false,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;
  final int? minLines;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final bool primaryOnScreenKeyboard;

  @override
  State<OnScreenKeyboardTextField> createState() =>
      _OnScreenKeyboardTextFieldState();
}

class _OnScreenKeyboardTextFieldState extends State<OnScreenKeyboardTextField> {
  late final FocusNode _focusNode;
  late final OnScreenKeyboardController _keyboard;
  late final OnScreenKeyboardType _keyboardType;
  late final VoidCallback _attachFocusedHandler;
  late final VoidCallback _activatePrimaryHandler;
  bool _ownsFocusNode = true;
  bool _wasKeyboardVisible = false;

  bool get _useOnScreenKeyboard => PlatformLayout.isDesktopPlatform;

  @override
  void initState() {
    super.initState();
    _keyboard = sl<OnScreenKeyboardController>();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _keyboardType = keyboardTypeFromInput(widget.keyboardType);
    _focusNode.addListener(_handleFocusChange);
    _attachFocusedHandler = _attachIfFocused;
    OnScreenKeyboardRegistry.register(_attachFocusedHandler);
    _activatePrimaryHandler = _activatePrimary;
    if (widget.primaryOnScreenKeyboard) {
      OnScreenKeyboardRegistry.registerPrimary(_activatePrimaryHandler);
      _wasKeyboardVisible = _keyboard.isVisible;
      _keyboard.addListener(_handleKeyboardVisibility);
      if (_keyboard.isVisible) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _activatePrimary();
          }
        });
      }
    }
  }

  void _activatePrimary() {
    if (!_useOnScreenKeyboard || !widget.primaryOnScreenKeyboard) {
      return;
    }
    if (!_focusNode.hasFocus && _focusNode.canRequestFocus) {
      _focusNode.requestFocus();
    }
    _attachActiveField();
  }

  void _handleKeyboardVisibility() {
    final visible = _keyboard.isVisible;
    if (!_useOnScreenKeyboard ||
        !widget.primaryOnScreenKeyboard ||
        !mounted) {
      _wasKeyboardVisible = visible;
      return;
    }

    if (visible && !_wasKeyboardVisible) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _activatePrimary();
        }
      });
    }

    _wasKeyboardVisible = visible;
  }

  @override
  void didUpdateWidget(covariant OnScreenKeyboardTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_handleFocusChange);
      if (_ownsFocusNode) {
        _focusNode.dispose();
      }
      _ownsFocusNode = widget.focusNode == null;
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    OnScreenKeyboardRegistry.unregister(_attachFocusedHandler);
    if (widget.primaryOnScreenKeyboard) {
      OnScreenKeyboardRegistry.unregisterPrimary(_activatePrimaryHandler);
      _keyboard.removeListener(_handleKeyboardVisibility);
    }
    _focusNode.removeListener(_handleFocusChange);
    _keyboard.detach(widget.controller);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _attachActiveField() {
    if (!_useOnScreenKeyboard || !_keyboard.isVisible) {
      return;
    }
    _keyboard.attach(
      widget.controller,
      type: _keyboardType,
      onChanged: widget.onChanged,
    );
  }

  void _attachIfFocused() {
    if (!_focusNode.hasFocus) {
      return;
    }
    _attachActiveField();
  }

  void _handleFocusChange() {
    if (!_useOnScreenKeyboard) {
      return;
    }
    if (_focusNode.hasFocus && _keyboard.isVisible) {
      _attachActiveField();
    } else if (!_focusNode.hasFocus && !_keyboard.isVisible) {
      _keyboard.detach(widget.controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    final common = (
      controller: widget.controller,
      focusNode: _focusNode,
      decoration: widget.decoration,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      onTap: () {
        if (_useOnScreenKeyboard && _keyboard.isVisible) {
          _attachActiveField();
        }
      },
    );

    if (widget.validator == null) {
      return TextField(
        controller: common.controller,
        focusNode: common.focusNode,
        decoration: common.decoration,
        keyboardType: common.keyboardType,
        textInputAction: widget.textInputAction,
        style: common.style,
        textAlign: common.textAlign,
        maxLines: common.maxLines,
        minLines: common.minLines,
        inputFormatters: common.inputFormatters,
        onChanged: common.onChanged,
        onSubmitted: widget.onSubmitted,
        onEditingComplete: widget.onEditingComplete,
        enabled: common.enabled,
        readOnly: common.readOnly,
        obscureText: widget.obscureText,
        onTap: common.onTap,
      );
    }

    return TextFormField(
      controller: common.controller,
      focusNode: common.focusNode,
      decoration: common.decoration,
      keyboardType: common.keyboardType,
      textInputAction: widget.textInputAction,
      style: common.style,
      textAlign: common.textAlign,
      maxLines: common.maxLines,
      minLines: common.minLines,
      inputFormatters: common.inputFormatters,
      onChanged: common.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
      enabled: common.enabled,
      readOnly: common.readOnly,
      obscureText: widget.obscureText,
      onTap: common.onTap,
      validator: widget.validator,
    );
  }
}
