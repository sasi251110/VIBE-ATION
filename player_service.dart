import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../core/models/track.dart';
import '../features/effects/effects_controller.dart';
import '../features/effects/effects_state.dart';

/// Single long-lived playback manager (Android, ExoPlayer via just_audio).
/// Not tied to any screen's lifetime.
class PlayerService {
  PlayerService({required this.effects});

  final EffectsState Function() effects;
  final AndroidEqualizer eq = AndroidEqualizer();
  final AndroidLoudnessEnhancer boost = AndroidLoudnessEnhancer();

  late final AudioPlayer player = AudioPlayer(
    audioPipeline: AudioPipeline(androidAudioEffects: [boost, eq]),
  );

  ConcatenatingAudioSource? _queue;

  Stream<MediaItem?> get nowPlaying => player.sequenceStateStream
      .map((s) => s?.currentSource?.tag as MediaItem?)
      .distinct((a, b) => a?.id == b?.id);

  AudioSource _source(Track t) => AudioSource.uri(
        Uri.file(t.path),
        tag: MediaItem(id: t.path, title: t.title, artist: t.artist),
      );

  /// Replaces the queue and starts playing [tracks] at [index].
  /// Throws [PlayerException] if the file cannot be loaded.
  Future<void> playTracks(List<Track> tracks, int index) async {
    final q = ConcatenatingAudioSource(children: tracks.map(_source).toList());
    _queue = q;
    await player.setAudioSource(q, initialIndex: index);
    await applyEffects(effects());
    unawaited(player.play());
  }

  Future<void> addToQueue(Track t) async {
    final q = _queue;
    if (q == null) {
      await playTracks([t], 0);
    } else {
      await q.add(_source(t));
    }
  }

  Future<void> removeFromQueue(int index) async => _queue?.removeAt(index);

  Future<void> moveInQueue(int from, int to) async => _queue?.move(from, to);

  Future<void> playQueueIndex(int index) async {
    await player.seek(Duration.zero, index: index);
    unawaited(player.play());
  }

  Future<void> clearQueue() async {
    await player.stop();
    await _queue?.clear();
    _queue = null;
  }

  Future<void> togglePlay() async {
    if (player.playing) {
      await player.pause();
    } else {
      unawaited(player.play());
    }
  }

  Future<void> next() => player.seekToNext();
  Future<void> previous() => player.seekToPrevious();

  Future<void> cycleLoopMode() {
    final next = switch (player.loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    return player.setLoopMode(next);
  }

  Future<void> toggleShuffle() async {
    final enable = !player.shuffleModeEnabled;
    if (enable) await player.shuffle();
    await player.setShuffleModeEnabled(enable);
  }

  Future<void> applyEffects(EffectsState e) async {
    try {
      await player.setSpeed(e.speed);
      await player.setPitch(e.pitch);
      await setBoostPercent(e.boostPercent);
      await applyEq(e.eqGains, e.eqEnabled);
    } catch (err) {
      debugPrint('Applying effects failed: $err');
    }
  }

  Future<void> setBoostPercent(double percent) async {
    await boost.setEnabled(percent > 100);
    await boost.setTargetGain(boostDb(percent));
  }

  Future<void> applyEq(List<double> gains, bool enabled) async {
    final params = await eq.parameters;
    final g = resampleCurve(gains, params.bands.length);
    for (var i = 0; i < params.bands.length; i++) {
      final v = g[i].clamp(params.minDecibels, params.maxDecibels).toDouble();
      await params.bands[i].setGain(v);
    }
    await eq.setEnabled(enabled);
  }

  Future<void> dispose() => player.dispose();
}

final playerServiceProvider = Provider<PlayerService>((ref) {
  final s = PlayerService(effects: () => ref.read(effectsControllerProvider));
  ref.onDispose(s.dispose);
  return s;
});

final nowPlayingProvider = StreamProvider<MediaItem?>(
  (ref) => ref.watch(playerServiceProvider).nowPlaying,
);
