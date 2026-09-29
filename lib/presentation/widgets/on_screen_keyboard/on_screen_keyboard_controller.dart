import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'on_screen_keyboard_registry.dart';
import 'on_screen_keyboard_language.dart';
import 'on_screen_keyboard_layouts.dart';
import 'on_screen_keyboard_page.dart';
import 'on_screen_keyboard_type.dart';

class OnScreenKeyboardController extends ChangeNotifier {
  bool _visible = false;
  TextEditingController? _target;
  OnScreenKeyboardType _inputType = OnScreenKeyboardType.text;
  OnScreenKeyboardLanguage _language = OnScreenKeyboardLanguage.russian;
  OnScreenKeyboardPage _page = OnScreenKeyboardPage.letters;
  bool _shiftActive = false;

  bool get isVisible => _visible;
  TextEditingController? get target => _target;
  OnScreenKeyboardType get inputType => _inputType;
  OnScreenKeyboardLanguage get language => _language;
  OnScreenKeyboardPage get page => _page;
  bool get isSymbolsPage => _page == OnScreenKeyboardPage.symbols;
  bool get isShiftActive => _shiftActive;

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
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid ||
        selection.start < 0 ||
        selection.end < 0) {
      controller.selection = TextSelection.collapsed(offset: text.length);
      return;
    }

    // Desktop иногда выделяет весь текст при потере/возврате фокуса.
    if (!selection.isCollapsed &&
        text.isNotEmpty &&
        selection.start == 0 &&
        selection.end == text.length) {
      controller.selection = TextSelection.collapsed(offset: text.length);
    }
  }

  void _restoreTargetSelection() {
    final controller = _target;
    if (controller == null) {
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _ensureSelection(controller);
    });
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

    _ensureSelection(controller);

    var output = text;
    if (_shiftActive && OnScreenKeyboardLayouts.isShiftable(text)) {
      output = text.toUpperCase();
      _shiftActive = false;
    }

    final value = controller.value;
    final selection = value.selection;
    final start = selection.start >= 0 ? selection.start : value.text.length;
    final end = selection.end >= 0 ? selection.end : value.text.length;
    final newText = value.text.replaceRange(start, end, output);
    controller.value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: start + output.length),
      composing: TextRange.empty,
    );
    _notifyTargetChanged();

    if (!_shiftActive && text != output) {
      notifyListeners();
      _restoreTargetSelection();
    }
  }

  void backspace() {
    if (_target == null && _visible) {
      OnScreenKeyboardRegistry.attachFocusedField();
    }

    final controller = _target;
    if (controller == null) {
      return;
    }

    _ensureSelection(controller);

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
    _shiftActive = false;
    notifyListeners();
    _restoreTargetSelection();
  }

  void setPage(OnScreenKeyboardPage page) {
    if (_page == page) {
      return;
    }
    _page = page;
    _shiftActive = false;
    notifyListeners();
    _restoreTargetSelection();
  }

  void toggleShift() {
    _shiftActive = !_shiftActive;
    notifyListeners();
    _restoreTargetSelection();
  }

  String displayKey(String key) {
    if (!_shiftActive || !OnScreenKeyboardLayouts.isShiftable(key)) {
      return key;
    }
    return key.toUpperCase();
  }

  void showSymbols() => setPage(OnScreenKeyboardPage.symbols);

  void showLetters() => setPage(OnScreenKeyboardPage.letters);
}
