import 'package:flutter/material.dart';

/// Turquoise-based palette with mint neutrals and slate text.
abstract final class AppColors {
  // Primary turquoise
  static const Color turquoise = Color(0xFF26A69A);
  static const Color turquoiseDark = Color(0xFF00897B);
  static const Color turquoiseLight = Color(0xFF4DB6AC);
  static const Color mint = Color(0xFFB2DFDB);
  static const Color mintSoft = Color(0xFFE0F2F1);

  // Surfaces & backgrounds
  static const Color background = Color(0xFFF5FAFA);
  static const Color surfaceMuted = Color(0xFFDCEFEA);
  static const Color surfaceCard = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1A3C38);
  static const Color textSecondary = Color(0xFF5A7A76);

  // Semantic
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFE9B949);
  static const Color error = Color(0xFFE57373);

  // Legacy aliases (used across widgets)
  static const Color cream = background;
  static const Color creamDark = surfaceMuted;
  static const Color deepBrown = turquoiseDark;
  static const Color deepBrownLight = textSecondary;
  static const Color pastelPink = mint;
  static const Color pastelPinkAccent = turquoiseLight;
  static const Color chocolate = textPrimary;
}
