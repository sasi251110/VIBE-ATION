import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/theme_controller.dart';
import 'core/theme/vibe_theme.dart';
import 'features/shell/app_shell.dart';

class VibeationApp extends ConsumerWidget {
  const VibeationApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeControllerProvider);
    return MaterialApp(
      title: 'VIBE-ATION',
      debugShowCheckedModeBanner: false,
      theme: buildVibeTheme(settings),
      home: const AppShell(),
    );
  }
}
