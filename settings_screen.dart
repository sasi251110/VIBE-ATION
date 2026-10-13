import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/theme/theme_settings.dart';
import '../../core/theme/vibe_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Preferences', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        Text('Theme', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<VibeThemeMode>(
          segments: const [
            ButtonSegment(value: VibeThemeMode.dark, label: Text('Dark')),
            ButtonSegment(value: VibeThemeMode.amoled, label: Text('AMOLED')),
            ButtonSegment(value: VibeThemeMode.light, label: Text('Light')),
          ],
          selected: {settings.mode},
          onSelectionChanged: (s) => controller.setMode(s.first),
        ),
        const SizedBox(height: 24),
        Text('Accent color', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final c in VibeColors.accents)
              _AccentSwatch(
                color: c,
                selected: c.value == settings.accent.value,
                onTap: () => controller.setAccent(c),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Player layout', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<PlayerMode>(
          segments: const [
            ButtonSegment(value: PlayerMode.vinyl, label: Text('Vinyl')),
            ButtonSegment(value: PlayerMode.album, label: Text('Album')),
            ButtonSegment(value: PlayerMode.minimal, label: Text('Minimal')),
          ],
          selected: {settings.playerMode},
          onSelectionChanged: (s) => controller.setPlayerMode(s.first),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Spin vinyl disc'),
          value: settings.vinylSpin,
          onChanged: controller.setVinylSpin,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Performance mode'),
          subtitle: const Text('Disables page transitions and disc spin.'),
          value: settings.performanceMode,
          onChanged: controller.setPerformanceMode,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: controller.resetDefaults,
          icon: const Icon(Icons.restore),
          label: const Text('Restore defaults'),
        ),
        const SizedBox(height: 24),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline),
          title: const Text('About VIBE-ATION'),
          subtitle: const Text('Feel Every Beat. Shape Your Sound.'),
          onTap: () => showAboutDialog(
            context: context,
            applicationName: 'VIBE-ATION',
            applicationVersion: '0.1.0',
            children: const [
              Text('Offline music player and audio studio. Early development.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Accent color',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? Colors.white : Colors.transparent,
              width: 3,
            ),
          ),
          child: selected ? const Icon(Icons.check, color: Colors.white) : null,
        ),
      ),
    );
  }
}
