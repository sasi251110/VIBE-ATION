import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../audio/player_service.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final np = ref.watch(nowPlayingProvider).valueOrNull;
    if (np == null) return const SizedBox.shrink();
    final svc = ref.watch(playerServiceProvider);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.music_note),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(np.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      np.artist ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous),
                tooltip: 'Previous',
                onPressed: svc.previous,
              ),
              StreamBuilder<PlayerState>(
                stream: svc.player.playerStateStream,
                builder: (context, s) {
                  final playing = s.data?.playing ?? false;
                  return IconButton(
                    icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                    tooltip: playing ? 'Pause' : 'Play',
                    onPressed: svc.togglePlay,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                tooltip: 'Next',
                onPressed: svc.next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
