import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/player_service.dart';
import '../../core/models/track.dart';
import '../../widgets/prompt.dart';
import '../../widgets/status_placeholder.dart';
import 'library_controller.dart';

enum _Sort { added, title, artist }

Future<void> playFrom(
  BuildContext context,
  WidgetRef ref,
  List<Track> list,
  int index,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final track = list[index];
  if (!File(track.path).existsSync()) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('File not found: ${track.fileName}'),
        action: SnackBarAction(
          label: 'Remove',
          onPressed: () =>
              ref.read(libraryControllerProvider.notifier).removeTrack(track.id),
        ),
      ),
    );
    return;
  }
  try {
    await ref.read(playerServiceProvider).playTracks(list, index);
    await ref.read(libraryControllerProvider.notifier).markPlayed(track.id);
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('Cannot play ${track.fileName}: $e')),
    );
  }
}

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _query = '';
  _Sort _sort = _Sort.added;

  List<Track> _filter(List<Track> src) {
    final q = _query.trim().toLowerCase();
    final out = q.isEmpty
        ? List<Track>.of(src)
        : src
            .where(
              (t) =>
                  t.title.toLowerCase().contains(q) ||
                  t.artist.toLowerCase().contains(q) ||
                  t.fileName.toLowerCase().contains(q),
            )
            .toList();
    if (_sort == _Sort.title) {
      out.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (_sort == _Sort.artist) {
      out.sort(
        (a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
      );
    }
    return out;
  }

  Future<void> _addFiles() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );
      if (res == null) return;
      final paths = res.paths.whereType<String>().toList();
      final added =
          await ref.read(libraryControllerProvider.notifier).addPaths(paths);
      messenger.showSnackBar(SnackBar(content: Text('Added $added track(s)')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not add files: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lib = ref.watch(libraryControllerProvider);
    final songs = _filter(lib.tracks);
    final favs = _filter(lib.resolve(lib.favorites));
    final recents = _filter(lib.resolve(lib.recents));

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search title, artist or filename',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                PopupMenuButton<_Sort>(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Sort',
                  onSelected: (s) => setState(() => _sort = s),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: _Sort.added, child: Text('Date added')),
                    PopupMenuItem(value: _Sort.title, child: Text('Title')),
                    PopupMenuItem(value: _Sort.artist, child: Text('Artist')),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.library_add),
                  tooltip: 'Add audio files',
                  onPressed: _addFiles,
                ),
              ],
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Songs'),
              Tab(text: 'Favorites'),
              Tab(text: 'Recent'),
              Tab(text: 'Playlists'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _TrackList(tracks: songs, empty: 'No songs yet. Tap + to add audio files.'),
                _TrackList(tracks: favs, empty: 'No favorites yet.'),
                _TrackList(tracks: recents, empty: 'Nothing played yet.'),
                const _PlaylistsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackList extends ConsumerWidget {
  const _TrackList({required this.tracks, required this.empty});

  final List<Track> tracks;
  final String empty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tracks.isEmpty) {
      return StatusPlaceholder(
        icon: Icons.library_music,
        title: 'Empty',
        status: empty,
      );
    }
    final favs = ref.watch(libraryControllerProvider).favorites;
    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (context, i) {
        final t = tracks[i];
        return ListTile(
          leading: const Icon(Icons.music_note),
          title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(t.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => playFrom(context, ref, tracks, i),
          trailing: PopupMenuButton<String>(
            onSelected: (v) => _onAction(context, ref, t, v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'queue', child: Text('Add to queue')),
              PopupMenuItem(
                value: 'fav',
                child: Text(
                  favs.contains(t.id) ? 'Remove favorite' : 'Add to favorites',
                ),
              ),
              const PopupMenuItem(
                value: 'playlist',
                child: Text('Add to playlist'),
              ),
              const PopupMenuItem(
                value: 'remove',
                child: Text('Remove from library'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    Track t,
    String action,
  ) async {
    final lib = ref.read(libraryControllerProvider.notifier);
    switch (action) {
      case 'queue':
        try {
          await ref.read(playerServiceProvider).addToQueue(t);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Cannot queue: $e')));
          }
        }
      case 'fav':
        await lib.toggleFavorite(t.id);
      case 'remove':
        await lib.removeTrack(t.id);
      case 'playlist':
        await _addToPlaylist(context, ref, t);
    }
  }

  Future<void> _addToPlaylist(
    BuildContext context,
    WidgetRef ref,
    Track t,
  ) async {
    final lib = ref.read(libraryControllerProvider.notifier);
    final names = ref.read(libraryControllerProvider).playlists.keys.toList();
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Add to playlist'),
        children: [
          for (final n in names)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, n),
              child: Text(n),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, '\u0000new'),
            child: const Text('+ New playlist'),
          ),
        ],
      ),
    );
    if (choice == null) return;
    var name = choice;
    if (choice == '\u0000new') {
      if (!context.mounted) return;
      final entered = await promptText(context, title: 'Playlist name');
      if (entered == null || !await lib.createPlaylist(entered)) return;
      name = entered.trim();
    }
    await lib.addToPlaylist(name, t.id);
  }
}

class _PlaylistsTab extends ConsumerWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lib = ref.watch(libraryControllerProvider);
    final names = lib.playlists.keys.toList();
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('New playlist'),
          onTap: () async {
            final n = await promptText(context, title: 'Playlist name');
            if (n == null) return;
            final ok =
                await ref.read(libraryControllerProvider.notifier).createPlaylist(n);
            if (!ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Name is empty or already used')),
              );
            }
          },
        ),
        Expanded(
          child: ListView(
            children: [
              for (final n in names)
                ListTile(
                  leading: const Icon(Icons.queue_music),
                  title: Text(n),
                  subtitle: Text('${lib.playlists[n]!.length} tracks'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PlaylistPage(name: n),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class PlaylistPage extends ConsumerWidget {
  const PlaylistPage({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lib = ref.watch(libraryControllerProvider);
    final tracks = lib.resolve(lib.playlists[name] ?? const []);
    final ctrl = ref.read(libraryControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete playlist',
            onPressed: () async {
              final nav = Navigator.of(context);
              await ctrl.deletePlaylist(name);
              nav.pop();
            },
          ),
        ],
      ),
      floatingActionButton: tracks.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => playFrom(context, ref, tracks, 0),
              child: const Icon(Icons.play_arrow),
            ),
      body: tracks.isEmpty
          ? const Center(child: Text('Empty playlist'))
          : ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (context, i) => ListTile(
                leading: const Icon(Icons.music_note),
                title: Text(tracks[i].title),
                subtitle: Text(tracks[i].artist),
                onTap: () => playFrom(context, ref, tracks, i),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: 'Remove from playlist',
                  onPressed: () => ctrl.removeFromPlaylist(name, tracks[i].id),
                ),
              ),
            ),
    );
  }
}
