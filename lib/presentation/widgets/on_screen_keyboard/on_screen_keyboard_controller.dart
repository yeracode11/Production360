import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'on_screen_keyboard_registry.dart';
import 'on_screen_keyboard_language.dart';
import 'on_screen_keyboard_type.dart';

class OnScreenKeyboardController extends ChangeNotifier {
  bool _visible = false;
  TextEditingController? _target;
  OnScreenKeyboardType _inputType = OnScreenKeyboardType.text;
  OnScreenKeyboardLanguage _language = OnScreenKeyboardLanguage.russian;

  bool get isVisible => _visible;
  TextEditingController? get target => _target;
  OnScreenKeyboardType get inputType => _inputType;
  OnScreenKeyboardLanguage get language => _language;

  ValueChanged<String>? _targetOnChanged;

  void toggle() {
    if (_visible) {
      hide();
    } else {
      show();
    }
  }

  void show({OnScreenKeyboardType? inputType}) {
    _visible = true;
    if (inputType != null) {
      _inputType = inputType;
    }
    notifyListeners();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      OnScreenKeyboardRegistry.activatePrimaryField();
      OnScreenKeyboardRegistry.attachFocusedField();
    });
  }

  void hide() {
    if (!_visible && _target == null) {
      return;
    }
    _visible = false;
    _target = null;
    _targetOnChanged = null;
    notifyListeners();
  }

  void attach(
    TextEditingController controller, {
    required OnScreenKeyboardType type,
    ValueChanged<String>? onChanged,
  }) {
    if (!_visible) {
      return;
    }

    final sameTarget = _target == controller && _inputType == type;
    _target = controller;
    _inputType = type;
    _targetOnChanged = onChanged;
    _ensureSelection(controller);

    if (!sameTarget) {
      notifyListeners();
    }
  }

  void detach(TextEditingController controller) {
    if (_target != controller) {
      return;
    }
    _target = null;
    _targetOnChanged = null;
    notifyListeners();
  }

  void _ensureSelection(TextEditingController controller) {
    if (!controller.selection.isValid ||
        controller.selection.start < 0 ||
        controller.selection.end < 0) {
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    }
  }

  void _notifyTargetChanged() {
    final controller = _target;
    if (controller == null) {
      return;
    }
    _targetOnChanged?.call(controller.text);
  }

  void insert(String text) {
    if (_target == null && _visible) {
      OnScreenKeyboardRegistry.attachFocusedField();
    }

    final controller = _target;
    if (controller == null || text.isEmpty) {
      return;
    }

    final value = controller.value;
    final selection = value.selection;
    final start = selection.start >= 0 ? selection.start : value.text.length;
    final end = selection.end >= 0 ? selection.end : value.text.length;
    final newText = value.text.replaceRange(start, end, text);
    controller.value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: start + text.length),
      composing: TextRange.empty,
    );
    _notifyTargetChanged();
  }

  void backspace() {
    if (_target == null && _visible) {
      OnScreenKeyboardRegistry.attachFocusedField();
    }

    final controller = _target;
    if (controller == null) {
      return;
    }

    final value = controller.value;
    final selection = value.selection;
    if (!selection.isValid) {
      return;
    }

    if (!selection.isCollapsed) {
      final newText = value.text.replaceRange(selection.start, selection.end, '');
      controller.value = value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start),
        composing: TextRange.empty,
      );
      _notifyTargetChanged();
      return;
    }

    final index = selection.start;
    if (index <= 0) {
      return;
    }

    final newText = value.text.replaceRange(index - 1, index, '');
    controller.value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: index - 1),
      composing: TextRange.empty,
    );
    _notifyTargetChanged();
  }

  void insertNewline() {
    insert('\n');
  }

  void setLanguage(OnScreenKeyboardLanguage language) {
    if (_language == language) {
      return;
    }
    _language = language;
    notifyListeners();
  }
}
