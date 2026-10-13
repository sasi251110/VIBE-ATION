import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/player_service.dart';
import '../../widgets/prompt.dart';
import 'lrc_parser.dart';
import 'lyrics_controller.dart';

class LyricsScreen extends ConsumerStatefulWidget {
  const LyricsScreen({super.key});

  @override
  ConsumerState<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends ConsumerState<LyricsScreen> {
  static const double _lineExtent = 56;
  final _scroll = ScrollController();
  double _fontSize = 18;
  int _lastIndex = -2;
  String? _sidecarChecked;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _autoDiscover(String id) async {
    if (_sidecarChecked == id) return;
    _sidecarChecked = id;
    if (ref.read(lyricsControllerProvider).containsKey(id)) return;
    final found = await findSidecarLrc(id);
    if (found != null && mounted) {
      await ref.read(lyricsControllerProvider.notifier).save(id, found);
    }
  }

  Future<void> _import(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['lrc', 'txt'],
      );
      final path = res?.files.single.path;
      if (path == null) return;
      final text = decodeLyricsBytes(await File(path).readAsBytes());
      await ref.read(lyricsControllerProvider.notifier).save(id, text);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final np = ref.watch(nowPlayingProvider).valueOrNull;
    final svc = ref.watch(playerServiceProvider);
    final store = ref.watch(lyricsControllerProvider);
    final id = np?.id;
    if (id != null) _autoDiscover(id);
    final raw = id == null ? null : store[id];
    final parsed = raw == null ? null : parseLyrics(raw);

    return Scaffold(
      appBar: AppBar(
        title: Text(np?.title ?? 'Lyrics'),
        actions: [
          if (id != null) ...[
            IconButton(
              icon: const Icon(Icons.text_decrease),
              tooltip: 'Smaller text',
              onPressed: () =>
                  setState(() => _fontSize = (_fontSize - 2).clamp(12, 40)),
            ),
            IconButton(
              icon: const Icon(Icons.text_increase),
              tooltip: 'Larger text',
              onPressed: () =>
                  setState(() => _fontSize = (_fontSize + 2).clamp(12, 40)),
            ),
            IconButton(
              icon: const Icon(Icons.file_open),
              tooltip: 'Import .lrc / .txt',
              onPressed: () => _import(id),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit lyrics',
              onPressed: () async {
                final t = await promptText(
                  context,
                  title: 'Lyrics (plain text or LRC)',
                  initial: raw ?? '',
                  maxLines: 12,
                );
                if (t == null) return;
                final ctrl = ref.read(lyricsControllerProvider.notifier);
                if (t.trim().isEmpty) {
                  await ctrl.clear(id);
                } else {
                  await ctrl.save(id, t);
                }
              },
            ),
          ],
        ],
      ),
      body: id == null
          ? const Center(child: Text('Nothing playing.'))
          : parsed == null || parsed.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No lyrics saved. Import a .lrc file, or tap edit to type them in.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : parsed.synced
                  ? _synced(parsed, svc)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        parsed.plain,
                        style: TextStyle(fontSize: _fontSize, height: 1.5),
                      ),
                    ),
    );
  }

  Widget _synced(ParsedLyrics parsed, PlayerService svc) {
    final accent = Theme.of(context).colorScheme.primary;
    return StreamBuilder<Duration>(
      stream: svc.player.positionStream,
      builder: (context, snap) {
        final idx = currentLineIndex(parsed.lines, snap.data ?? Duration.zero);
        if (idx != _lastIndex) {
          _lastIndex = idx;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_scroll.hasClients || idx < 0) return;
            final target = (idx * _lineExtent - _scroll.position.viewportDimension / 3)
                .clamp(0.0, _scroll.position.maxScrollExtent);
            _scroll.animateTo(
              target,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
        }
        return ListView.builder(
          controller: _scroll,
          itemExtent: _lineExtent,
          itemCount: parsed.lines.length,
          itemBuilder: (context, i) {
            final active = i == idx;
            return Center(
              child: Text(
                parsed.lines[i].text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: active ? _fontSize + 4 : _fontSize,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: active ? accent : null,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
