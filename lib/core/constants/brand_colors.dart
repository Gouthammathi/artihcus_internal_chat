import 'package:flutter/material.dart';

abstract class BrandColors {
  static const Color primary = Color(0xFFF26A21);
  static const Color secondary = Color(0xFFFFA726);
  static const Color accent = Color(0xFFFFC857);
  static const Color neutralBackground = Color(0xFFFFF5EC);
  static const Color neutralForeground = Color(0xFF3A1E0B);
  static const Color subtleBorder = Color(0xFFFFE0CC);
}

extension ColorOpacityX on Color {
  Color withOpacityFraction(double opacity) {
    final alpha = (opacity.clamp(0, 1) * 255).round();
    return withAlpha(alpha);
  }
}
