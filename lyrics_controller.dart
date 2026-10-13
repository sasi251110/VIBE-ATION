import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/theme/theme_controller.dart';

final lyricsControllerProvider =
    NotifierProvider<LyricsController, Map<String, String>>(
  LyricsController.new,
);

/// Lyrics stored locally per track path. Fully offline.
class LyricsController extends Notifier<Map<String, String>> {
  static const _key = 'lyrics.v1';

  @override
  Map<String, String> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return {};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> _persist() => ref
      .read(sharedPreferencesProvider)
      .setString(_key, jsonEncode(state));

  Future<void> save(String trackId, String raw) async {
    state = {...state, trackId: raw};
    await _persist();
  }

  Future<void> clear(String trackId) async {
    state = {...state}..remove(trackId);
    await _persist();
  }
}

/// Decodes bytes as UTF-8, replacing invalid sequences instead of failing.
String decodeLyricsBytes(List<int> bytes) =>
    utf8.decode(bytes, allowMalformed: true);

/// Looks for Track.lrc next to Track.mp3. Returns null if missing/unreadable.
Future<String?> findSidecarLrc(String trackPath) async {
  try {
    final f = File(p.setExtension(trackPath, '.lrc'));
    if (!await f.exists()) return null;
    return decodeLyricsBytes(await f.readAsBytes());
  } catch (_) {
    return null;
  }
}
