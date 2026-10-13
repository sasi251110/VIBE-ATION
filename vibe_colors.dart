import 'package:flutter/material.dart';

/// Default VIBE-ATION brand palette. Users can override the accent.
class VibeColors {
  const VibeColors._();

  static const Color violet = Color(0xFF8B5CF6);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color black = Color(0xFF000000);
  static const Color charcoal = Color(0xFF121216);
  static const Color charcoalSurface = Color(0xFF1C1C24);
  static const Color lightBackground = Color(0xFFF6F5FA);

  /// Accent choices offered in Settings.
  static const List<Color> accents = [
    violet,
    cyan,
    Color(0xFFF43F5E),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
  ];
}
