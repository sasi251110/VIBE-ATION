import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/track.dart';
import '../../core/theme/theme_controller.dart';

@immutable
class LibraryState {
  const LibraryState({
    this.tracks = const [],
    this.favorites = const {},
    this.recents = const [],
    this.playlists = const {},
  });

  factory LibraryState.fromJson(Map<String, dynamic> j) => LibraryState(
        tracks: [
          for (final t in (j['tracks'] as List? ?? const []))
            Track.fromJson(Map<String, dynamic>.from(t as Map)),
        ],
        favorites: {
          for (final f in (j['favorites'] as List? ?? const [])) f as String,
        },
        recents: [
          for (final r in (j['recents'] as List? ?? const [])) r as String,
        ],
        playlists: {
          for (final e in ((j['playlists'] as Map?) ?? const {}).entries)
            e.key as String: [for (final id in e.value as List) id as String],
        },
      );

  final List<Track> tracks;
  final Set<String> favorites;
  final List<String> recents;
  final Map<String, List<String>> playlists;

  Track? byId(String id) {
    for (final t in tracks) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<Track> resolve(Iterable<String> ids) =>
      [for (final id in ids) if (byId(id) != null) byId(id)!];

  Map<String, dynamic> toJson() => {
        'tracks': [for (final t in tracks) t.toJson()],
        'favorites': favorites.toList(),
        'recents': recents,
        'playlists': playlists,
      };

  LibraryState copyWith({
    List<Track>? tracks,
    Set<String>? favorites,
    List<String>? recents,
    Map<String, List<String>>? playlists,
  }) =>
      LibraryState(
        tracks: tracks ?? this.tracks,
        favorites: favorites ?? this.favorites,
        recents: recents ?? this.recents,
        playlists: playlists ?? this.playlists,
      );
}

final libraryControllerProvider =
    NotifierProvider<LibraryController, LibraryState>(LibraryController.new);

class LibraryController extends Notifier<LibraryState> {
  static const _key = 'library.v1';

  @override
  LibraryState build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const LibraryState();
    try {
      return LibraryState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Library data unreadable, starting empty: $e');
      return const LibraryState();
    }
  }

  Future<void> _set(LibraryState s) async {
    state = s;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(s.toJson()));
  }

  /// Adds files, skipping duplicates. Returns the number actually added.
  Future<int> addPaths(List<String> paths) async {
    final known = {for (final t in state.tracks) t.path};
    final added = <Track>[];
    for (final path in paths) {
      if (known.add(path)) added.add(Track.fromPath(path));
    }
    if (added.isNotEmpty) {
      await _set(state.copyWith(tracks: [...state.tracks, ...added]));
    }
    return added.length;
  }

  Future<void> removeTrack(String id) => _set(
        LibraryState(
          tracks: state.tracks.where((t) => t.id != id).toList(),
          favorites: {...state.favorites}..remove(id),
          recents: state.recents.where((r) => r != id).toList(),
          playlists: {
            for (final e in state.playlists.entries)
              e.key: e.value.where((x) => x != id).toList(),
          },
        ),
      );

  Future<void> toggleFavorite(String id) {
    final favs = {...state.favorites};
    if (!favs.remove(id)) favs.add(id);
    return _set(state.copyWith(favorites: favs));
  }

  Future<void> markPlayed(String id) => _set(
        state.copyWith(
          recents: [id, ...state.recents.where((r) => r != id)].take(50).toList(),
        ),
      );

  Future<bool> createPlaylist(String name) async {
    final n = name.trim();
    if (n.isEmpty || state.playlists.containsKey(n)) return false;
    await _set(state.copyWith(playlists: {...state.playlists, n: <String>[]}));
    return true;
  }

  Future<void> deletePlaylist(String name) {
    final pl = {...state.playlists}..remove(name);
    return _set(state.copyWith(playlists: pl));
  }

  Future<void> addToPlaylist(String name, String id) {
    final list = state.playlists[name];
    if (list == null || list.contains(id)) return Future.value();
    return _set(
      state.copyWith(playlists: {...state.playlists, name: [...list, id]}),
    );
  }

  Future<void> removeFromPlaylist(String name, String id) {
    final list = state.playlists[name];
    if (list == null) return Future.value();
    return _set(
      state.copyWith(
        playlists: {...state.playlists, name: list.where((x) => x != id).toList()},
      ),
    );
  }
}
