import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibe_ation/core/theme/theme_controller.dart';
import 'package:vibe_ation/features/library/library_controller.dart';

ProviderContainer _c(SharedPreferences p) {
  final c = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(p)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('dedupes, favorites, playlists and recents persist', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = _c(prefs);
    final n = c.read(libraryControllerProvider.notifier);

    expect(await n.addPaths(['/m/a.mp3', '/m/a.mp3', '/m/b.flac']), 2);
    await n.toggleFavorite('/m/a.mp3');
    expect(await n.createPlaylist('Road'), isTrue);
    expect(await n.createPlaylist('Road'), isFalse);
    await n.addToPlaylist('Road', '/m/b.flac');
    await n.addToPlaylist('Road', '/m/b.flac');
    await n.markPlayed('/m/b.flac');

    final s = _c(prefs).read(libraryControllerProvider);
    expect(s.tracks.length, 2);
    expect(s.tracks.first.title, 'a');
    expect(s.favorites, {'/m/a.mp3'});
    expect(s.playlists['Road'], ['/m/b.flac']);
    expect(s.recents, ['/m/b.flac']);
  });

  test('removeTrack cleans favorites, recents and playlists', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final n = _c(prefs).read(libraryControllerProvider.notifier);
    await n.addPaths(['/m/a.mp3']);
    await n.toggleFavorite('/m/a.mp3');
    await n.createPlaylist('P');
    await n.addToPlaylist('P', '/m/a.mp3');
    await n.markPlayed('/m/a.mp3');
    await n.removeTrack('/m/a.mp3');

    final s = _c(prefs).read(libraryControllerProvider);
    expect(s.tracks, isEmpty);
    expect(s.favorites, isEmpty);
    expect(s.recents, isEmpty);
    expect(s.playlists['P'], isEmpty);
  });

  test('corrupt stored data falls back to empty library', () async {
    SharedPreferences.setMockInitialValues({'library.v1': '{not json'});
    final prefs = await SharedPreferences.getInstance();
    expect(_c(prefs).read(libraryControllerProvider).tracks, isEmpty);
  });
}
