import 'package:flutter/foundation.dart';

/// Реестр полей ввода для привязки к экранной клавиатуре.
abstract final class OnScreenKeyboardRegistry {
  static final _attachHandlers = <VoidCallback>{};
  static final List<VoidCallback> _primaryHandlers = [];

  static void register(VoidCallback attachFocused) {
    _attachHandlers.add(attachFocused);
  }

  static void unregister(VoidCallback attachFocused) {
    _attachHandlers.remove(attachFocused);
  }

  static void registerPrimary(VoidCallback activate) {
    if (!_primaryHandlers.contains(activate)) {
      _primaryHandlers.add(activate);
    }
  }

  static void unregisterPrimary(VoidCallback activate) {
    _primaryHandlers.remove(activate);
  }

  static void attachFocusedField() {
    for (final handler in List<VoidCallback>.from(_attachHandlers)) {
      handler();
    }
  }

  /// Фокусирует последнее зарегистрированное primary-поле (например, поиск).
  static void activatePrimaryField() {
    if (_primaryHandlers.isEmpty) {
      return;
    }
    _primaryHandlers.last();
  }
}
