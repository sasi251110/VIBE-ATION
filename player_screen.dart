import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../audio/player_service.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/theme/theme_settings.dart';
import '../../widgets/prompt.dart';
import '../lyrics/lyrics_screen.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  StreamSubscription<PlayerException>? _errSub;

  @override
  void initState() {
    super.initState();
    _errSub = ref.read(playerServiceProvider).player.errorStream.listen((e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playback error: ${e.message ?? e.code}')),
      );
    });
  }

  @override
  void dispose() {
    _errSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = ref.watch(playerServiceProvider);
    final settings = ref.watch(themeControllerProvider);
    final np = ref.watch(nowPlayingProvider).valueOrNull;

    if (np == null) {
      return const Center(
        child: Text('Nothing playing. Pick a song in Library.'),
      );
    }

    return StreamBuilder<PlayerState>(
      stream: svc.player.playerStateStream,
      builder: (context, snap) {
        final playing = snap.data?.playing ?? false;
        final spinning =
            playing && settings.vinylSpin && !settings.performanceMode;
        return LayoutBuilder(
          builder: (context, c) {
            final art = (c.maxHeight * 0.38).clamp(120.0, 320.0);
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Artwork(
                        mode: settings.playerMode,
                        size: settings.playerMode == PlayerMode.minimal
                            ? art * 0.5
                            : art,
                        spinning: spinning,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        np.title,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(np.artist ?? 'Unknown artist'),
                      const SizedBox(height: 8),
                      _SeekBar(player: svc.player),
                      _Controls(svc: svc, playing: playing),
                      const _NextUp(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.queue_music),
                            label: const Text('Queue'),
                            onPressed: () => _showQueue(context, svc),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.lyrics_outlined),
                            label: const Text('Lyrics'),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const LyricsScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showQueue(BuildContext context, PlayerService svc) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (ctx, scroll) => StreamBuilder<SequenceState?>(
          stream: svc.player.sequenceStateStream,
          builder: (ctx, snap) {
            final seq = snap.data?.sequence ?? const [];
            final cur = snap.data?.currentIndex;
            return Column(
              children: [
                ListTile(
                  title: const Text('Queue'),
                  trailing: TextButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await svc.clearQueue();
                    },
                    child: const Text('Clear'),
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    scrollController: scroll,
                    itemCount: seq.length,
                    onReorder: (a, b) {
                      if (b > a) b -= 1;
                      svc.moveInQueue(a, b);
                    },
                    itemBuilder: (ctx, i) {
                      final item = seq[i].tag as MediaItem;
                      return ListTile(
                        key: ValueKey('$i-${item.id}'),
                        selected: i == cur,
                        leading: Icon(
                          i == cur ? Icons.equalizer : Icons.music_note,
                        ),
                        title: Text(item.title, maxLines: 1),
                        subtitle: Text(
                          cur != null && i == cur + 1
                              ? 'Next up'
                              : (item.artist ?? ''),
                        ),
                        onTap: () => svc.playQueueIndex(i),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Remove from queue',
                          onPressed: () => svc.removeFromQueue(i),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NextUp extends ConsumerWidget {
  const _NextUp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.watch(playerServiceProvider);
    return StreamBuilder<SequenceState?>(
      stream: svc.player.sequenceStateStream,
      builder: (context, snap) {
        final s = snap.data;
        final i = s?.currentIndex;
        if (s == null || i == null || i + 1 >= s.sequence.length) {
          return const SizedBox.shrink();
        }
        final next = s.sequence[i + 1].tag as MediaItem;
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Next: ${next.title}',
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}

class _SeekBar extends StatelessWidget {
  const _SeekBar({required this.player});

  final AudioPlayer player;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: player.durationStream,
      builder: (context, dSnap) {
        final total = dSnap.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: player.positionStream,
          builder: (context, pSnap) {
            final pos = pSnap.data ?? Duration.zero;
            final maxMs = total.inMilliseconds.toDouble();
            final value = pos.inMilliseconds
                .toDouble()
                .clamp(0, maxMs > 0 ? maxMs : 1)
                .toDouble();
            return Column(
              children: [
                Slider(
                  value: value,
                  max: maxMs > 0 ? maxMs : 1,
                  onChanged: maxMs > 0
                      ? (v) => player.seek(Duration(milliseconds: v.round()))
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatDuration(pos)),
                      Text(formatDuration(total)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.svc, required this.playing});

  final PlayerService svc;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final player = svc.player;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StreamBuilder<bool>(
          stream: player.shuffleModeEnabledStream,
          builder: (context, s) => IconButton(
            tooltip: 'Shuffle',
            icon: Icon(
              Icons.shuffle,
              color: (s.data ?? false)
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: svc.toggleShuffle,
          ),
        ),
        IconButton(
          iconSize: 40,
          tooltip: 'Previous',
          icon: const Icon(Icons.skip_previous),
          onPressed: svc.previous,
        ),
        IconButton.filled(
          iconSize: 48,
          tooltip: playing ? 'Pause' : 'Play',
          icon: Icon(playing ? Icons.pause : Icons.play_arrow),
          onPressed: svc.togglePlay,
        ),
        IconButton(
          iconSize: 40,
          tooltip: 'Next',
          icon: const Icon(Icons.skip_next),
          onPressed: svc.next,
        ),
        StreamBuilder<LoopMode>(
          stream: player.loopModeStream,
          builder: (context, s) {
            final mode = s.data ?? LoopMode.off;
            return IconButton(
              tooltip: 'Repeat',
              icon: Icon(
                mode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                color: mode == LoopMode.off
                    ? null
                    : Theme.of(context).colorScheme.primary,
              ),
              onPressed: svc.cycleLoopMode,
            );
          },
        ),
      ],
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({
    required this.mode,
    required this.size,
    required this.spinning,
  });

  final PlayerMode mode;
  final double size;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (mode == PlayerMode.vinyl) {
      return _VinylDisc(size: size, spinning: spinning);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(mode == PlayerMode.minimal ? 12 : 24),
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(Icons.music_note, size: size * 0.5, color: Colors.white),
    );
  }
}

class _VinylDisc extends StatefulWidget {
  const _VinylDisc({required this.size, required this.spinning});

  final double size;
  final bool spinning;

  @override
  State<_VinylDisc> createState() => _VinylDiscState();
}

class _VinylDiscState extends State<_VinylDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _VinylDisc old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.spinning) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = widget.size;
    return RotationTransition(
      turns: _c,
      child: Container(
        width: s,
        height: s,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              Colors.black,
              Color(0xFF2A2A33),
              Colors.black,
              Color(0xFF2A2A33),
              Colors.black,
            ],
          ),
        ),
        child: Center(
          child: Container(
            width: s * 0.36,
            height: s * 0.36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.secondary],
              ),
            ),
            child: Center(
              child: Container(
                width: s * 0.06,
                height: s * 0.06,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
