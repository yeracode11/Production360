import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Breakpoints and helpers for mobile vs desktop layout.
abstract final class PlatformLayout {
  static const desktopBreakpoint = 900.0;
  static const sidebarWidth = 260.0;

  static bool get isDesktopPlatform {
    if (kIsWeb) {
      return false;
    }
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  static bool useDesktopNavigation(BuildContext context) {
    if (!isDesktopPlatform) {
      return false;
    }
    return MediaQuery.sizeOf(context).width >= desktopBreakpoint;
  }
}
