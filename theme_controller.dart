import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_settings.dart';

/// Must be overridden in main() and in tests.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeSettings>(ThemeController.new);

class ThemeController extends Notifier<ThemeSettings> {
  static const _kMode = 'theme.mode';
  static const _kAccent = 'theme.accent';
  static const _kPerformance = 'theme.performance';
  static const _kPlayerMode = 'theme.playerMode';
  static const _kVinylSpin = 'theme.vinylSpin';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  ThemeSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    const defaults = ThemeSettings();
    final mode = VibeThemeMode.values.firstWhere(
      (m) => m.name == prefs.getString(_kMode),
      orElse: () => defaults.mode,
    );
    final playerMode = PlayerMode.values.firstWhere(
      (m) => m.name == prefs.getString(_kPlayerMode),
      orElse: () => defaults.playerMode,
    );
    final accentValue = prefs.getInt(_kAccent);
    return ThemeSettings(
      mode: mode,
      accent: accentValue == null ? defaults.accent : Color(accentValue),
      performanceMode: prefs.getBool(_kPerformance) ?? defaults.performanceMode,
      playerMode: playerMode,
      vinylSpin: prefs.getBool(_kVinylSpin) ?? defaults.vinylSpin,
    );
  }

  Future<void> setMode(VibeThemeMode mode) async {
    state = state.copyWith(mode: mode);
    await _prefs.setString(_kMode, mode.name);
  }

  Future<void> setAccent(Color color) async {
    state = state.copyWith(accent: color);
    await _prefs.setInt(_kAccent, color.value);
  }

  Future<void> setPerformanceMode(bool enabled) async {
    state = state.copyWith(performanceMode: enabled);
    await _prefs.setBool(_kPerformance, enabled);
  }

  Future<void> setPlayerMode(PlayerMode mode) async {
    state = state.copyWith(playerMode: mode);
    await _prefs.setString(_kPlayerMode, mode.name);
  }

  Future<void> setVinylSpin(bool enabled) async {
    state = state.copyWith(vinylSpin: enabled);
    await _prefs.setBool(_kVinylSpin, enabled);
  }

  Future<void> resetDefaults() async {
    state = const ThemeSettings();
    for (final k in [_kMode, _kAccent, _kPerformance, _kPlayerMode, _kVinylSpin]) {
      await _prefs.remove(k);
    }
  }
}
