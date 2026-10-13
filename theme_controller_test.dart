import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibe_ation/core/theme/theme_controller.dart';
import 'package:vibe_ation/core/theme/theme_settings.dart';
import 'package:vibe_ation/core/theme/vibe_colors.dart';

ProviderContainer _container(SharedPreferences prefs) {
  final c = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('defaults are dark, violet, performance off', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final s = _container(prefs).read(themeControllerProvider);
    expect(s.mode, VibeThemeMode.dark);
    expect(s.accent, VibeColors.violet);
    expect(s.performanceMode, isFalse);
  });

  test('settings persist across containers', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final n = _container(prefs).read(themeControllerProvider.notifier);
    await n.setMode(VibeThemeMode.amoled);
    await n.setAccent(VibeColors.cyan);
    await n.setPerformanceMode(true);

    final s = _container(prefs).read(themeControllerProvider);
    expect(s.mode, VibeThemeMode.amoled);
    expect(s.accent.value, VibeColors.cyan.value);
    expect(s.performanceMode, isTrue);
  });

  test('resetDefaults restores defaults and clears storage', () async {
    SharedPreferences.setMockInitialValues({'theme.mode': 'light'});
    final prefs = await SharedPreferences.getInstance();
    final c = _container(prefs);
    expect(c.read(themeControllerProvider).mode, VibeThemeMode.light);

    await c.read(themeControllerProvider.notifier).resetDefaults();
    expect(c.read(themeControllerProvider).mode, VibeThemeMode.dark);
    expect(prefs.getString('theme.mode'), isNull);
  });

  test('invalid stored mode falls back to default', () async {
    SharedPreferences.setMockInitialValues({'theme.mode': 'bogus'});
    final prefs = await SharedPreferences.getInstance();
    final s = _container(prefs).read(themeControllerProvider);
    expect(s.mode, VibeThemeMode.dark);
  });
}
