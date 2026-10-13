import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../audio/player_service.dart';
import '../../widgets/prompt.dart';
import 'effects_controller.dart';
import 'effects_state.dart';

class EffectsScreen extends ConsumerWidget {
  const EffectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fx = ref.watch(effectsControllerProvider);
    final ctrl = ref.read(effectsControllerProvider.notifier);
    final np = ref.watch(nowPlayingProvider).valueOrNull;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Audio effects', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Text('Speed: ${fx.speed.toStringAsFixed(2)}x'),
        Slider(
          value: fx.speed,
          min: 0.5,
          max: 2.0,
          divisions: 30,
          onChanged: ctrl.setSpeed,
        ),
        Text('Pitch: ${fx.pitch.toStringAsFixed(2)}x'),
        Slider(
          value: fx.pitch,
          min: 0.5,
          max: 2.0,
          divisions: 30,
          onChanged: ctrl.setPitch,
        ),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: ctrl.applySlowed,
              child: const Text('Slowed (0.85x)'),
            ),
            OutlinedButton(
              onPressed: () async {
                await ctrl.setSpeed(1.0);
                await ctrl.setPitch(1.0);
              },
              child: const Text('Normal speed'),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            'Speed and pitch change together. Reverb is not implemented yet, so this is "Slowed" only, not "Slowed + Reverb".',
            style: TextStyle(fontSize: 12),
          ),
        ),
        const Divider(height: 32),
        Text('Volume boost: ${fx.boostPercent.round()}%'),
        Slider(
          value: fx.boostPercent,
          min: 100,
          max: 300,
          divisions: 40,
          onChanged: ctrl.setBoost,
        ),
        Text(
          fx.boostPercent > 100
              ? 'Warning: boosting above 100% can distort and be very loud. '
                  '300% means about +9.5 dB gain. Android LoudnessEnhancer is not a hard limiter.'
              : 'Normal level.',
          style: TextStyle(
            fontSize: 12,
            color: fx.boostPercent > 150
                ? Theme.of(context).colorScheme.error
                : null,
          ),
        ),
        const Divider(height: 32),
        Text('Equalizer', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final name in [...kEqPresets.keys, ...fx.customPresets.keys])
              ChoiceChip(
                label: Text(name),
                selected: fx.eqEnabled && fx.presetName == name,
                onSelected: (_) => ctrl.applyPreset(name),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (np == null)
          const Text('Play a song to adjust the equalizer bands.')
        else
          _EqBands(fx: fx),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: ctrl.resetAll,
          icon: const Icon(Icons.restore),
          label: const Text('Reset all effects'),
        ),
      ],
    );
  }
}

class _EqBands extends ConsumerWidget {
  const _EqBands({required this.fx});

  final EffectsState fx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.watch(playerServiceProvider);
    final ctrl = ref.read(effectsControllerProvider.notifier);
    return FutureBuilder<AndroidEqualizerParameters>(
      future: svc.eq.parameters,
      builder: (context, snap) {
        final params = snap.data;
        if (params == null) return const Text('Equalizer starting...');
        final n = params.bands.length;
        final gains = resampleCurve(fx.eqGains, n);
        return Column(
          children: [
            for (var i = 0; i < n; i++)
              Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(_freq(params.bands[i].centerFrequency)),
                  ),
                  Expanded(
                    child: Slider(
                      value: gains[i]
                          .clamp(params.minDecibels, params.maxDecibels)
                          .toDouble(),
                      min: params.minDecibels,
                      max: params.maxDecibels,
                      onChanged: (v) => ctrl.setEqGain(i, n, v),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text('${gains[i].toStringAsFixed(1)} dB'),
                  ),
                ],
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save as preset'),
                onPressed: () async {
                  final name = await promptText(context, title: 'Preset name');
                  if (name != null) await ctrl.saveCustomPreset(name, n);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _freq(double hz) =>
      hz >= 1000 ? '${(hz / 1000).toStringAsFixed(1)} kHz' : '${hz.round()} Hz';
}
