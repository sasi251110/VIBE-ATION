import 'package:flutter/material.dart';

import 'vibe_colors.dart';

enum VibeThemeMode { dark, amoled, light }

enum PlayerMode { vinyl, album, minimal }

@immutable
class ThemeSettings {
  const ThemeSettings({
    this.mode = VibeThemeMode.dark,
    this.accent = VibeColors.violet,
    this.performanceMode = false,
    this.playerMode = PlayerMode.vinyl,
    this.vinylSpin = true,
  });

  final VibeThemeMode mode;
  final Color accent;
  final bool performanceMode;
  final PlayerMode playerMode;
  final bool vinylSpin;

  ThemeSettings copyWith({
    VibeThemeMode? mode,
    Color? accent,
    bool? performanceMode,
    PlayerMode? playerMode,
    bool? vinylSpin,
  }) {
    return ThemeSettings(
      mode: mode ?? this.mode,
      accent: accent ?? this.accent,
      performanceMode: performanceMode ?? this.performanceMode,
      playerMode: playerMode ?? this.playerMode,
      vinylSpin: vinylSpin ?? this.vinylSpin,
    );
  }
}
