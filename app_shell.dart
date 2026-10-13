import 'package:flutter/material.dart';

import '../effects/effects_screen.dart';
import '../library/library_screen.dart';
import '../player/player_screen.dart';
import '../settings/settings_screen.dart';
import 'mini_player.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _destinations = <_Destination>[
  _Destination('Library', Icons.library_music_outlined, Icons.library_music),
  _Destination('Player', Icons.play_circle_outline, Icons.play_circle),
  _Destination('Effects', Icons.equalizer_outlined, Icons.equalizer),
  _Destination('Settings', Icons.settings_outlined, Icons.settings),
];

/// Width at which the layout switches from bottom bar to side rail.
const double kWideLayoutBreakpoint = 800;

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  // Pages are built on demand so audio is only touched when needed.
  Widget _page() {
    switch (_index) {
      case 0:
        return const LibraryScreen();
      case 1:
        return const PlayerScreen();
      case 2:
        return const EffectsScreen();
      default:
        return const SettingsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= kWideLayoutBreakpoint;
    final body = SafeArea(
      child: Column(
        children: [
          Expanded(child: _page()),
          if (_index != 1) MiniPlayer(onOpen: () => setState(() => _index = 1)),
        ],
      ),
    );

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
