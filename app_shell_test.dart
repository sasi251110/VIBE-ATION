import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibe_ation/app.dart';
import 'package:vibe_ation/audio/player_service.dart';
import 'package:vibe_ation/core/theme/theme_controller.dart';

Future<void> _pump(WidgetTester tester, Size size) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowPlayingProvider.overrideWith((ref) => Stream<MediaItem?>.value(null)),
      ],
      child: const VibeationApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('narrow layout uses bottom NavigationBar', (tester) async {
    await _pump(tester, const Size(400, 800));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('wide layout uses NavigationRail', (tester) async {
    await _pump(tester, const Size(1200, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('library shows empty state', (tester) async {
    await _pump(tester, const Size(400, 800));
    expect(find.textContaining('No songs yet'), findsOneWidget);
  });

  testWidgets('can open Settings and toggle performance mode', (tester) async {
    await _pump(tester, const Size(400, 800));
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    final tile = find.widgetWithText(SwitchListTile, 'Performance mode');
    await tester.ensureVisible(tile);
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);
  });
}
