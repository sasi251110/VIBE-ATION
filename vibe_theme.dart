import 'package:flutter/material.dart';

import 'theme_settings.dart';
import 'vibe_colors.dart';

ThemeData buildVibeTheme(ThemeSettings s) {
  final isLight = s.mode == VibeThemeMode.light;
  final brightness = isLight ? Brightness.light : Brightness.dark;

  final Color background;
  final Color surface;
  switch (s.mode) {
    case VibeThemeMode.light:
      background = VibeColors.lightBackground;
      surface = Colors.white;
    case VibeThemeMode.amoled:
      background = VibeColors.black;
      surface = VibeColors.black;
    case VibeThemeMode.dark:
      background = VibeColors.charcoal;
      surface = VibeColors.charcoalSurface;
  }

  final scheme = ColorScheme.fromSeed(
    seedColor: s.accent,
    brightness: brightness,
  ).copyWith(primary: s.accent, secondary: VibeColors.cyan, surface: surface);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(backgroundColor: surface),
    navigationRailTheme: NavigationRailThemeData(backgroundColor: surface),
    pageTransitionsTheme: s.performanceMode
        ? const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: _NoTransitionBuilder(),
              TargetPlatform.windows: _NoTransitionBuilder(),
            },
          )
        : null,
  );
}

class _NoTransitionBuilder extends PageTransitionsBuilder {
  const _NoTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
