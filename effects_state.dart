import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Built-in EQ curves (dB) defined on 5 points, resampled to the device's
/// actual band count.
const Map<String, List<double>> kEqPresets = {
  'Flat': [0, 0, 0, 0, 0],
  'Bass Boost': [6, 4, 0, 0, 0],
  'Vocal': [-2, 0, 4, 3, -1],
  'Rock': [4, 2, -1, 2, 4],
  'Pop': [-1, 2, 4, 2, -1],
  'Classical': [3, 2, -1, 2, 3],
  'EDM': [5, 3, 0, 2, 4],
};

/// Linearly resamples a gain curve to [n] points.
List<double> resampleCurve(List<double> src, int n) {
  if (n <= 0) return <double>[];
  if (src.isEmpty) return List<double>.filled(n, 0);
  if (src.length == n) return List<double>.of(src);
  if (n == 1) return [src.first];
  final out = <double>[];
  for (var i = 0; i < n; i++) {
    final pos = i * (src.length - 1) / (n - 1);
    final lo = pos.floor();
    final hi = math.min(lo + 1, src.length - 1);
    out.add(src[lo] + (src[hi] - src[lo]) * (pos - lo));
  }
  return out;
}

/// Gain in dB for a nominal volume percentage (100% = 0 dB, 300% = ~9.54 dB,
/// i.e. 3x signal amplitude).
double boostDb(double percent) =>
    percent <= 100 ? 0 : 20 * math.log(percent / 100) / math.ln10;

@immutable
class EffectsState {
  const EffectsState({
    this.speed = 1.0,
    this.pitch = 1.0,
    this.boostPercent = 100,
    this.eqEnabled = false,
    this.eqGains = const [0, 0, 0, 0, 0],
    this.presetName = 'Flat',
    this.customPresets = const {},
  });

  factory EffectsState.fromJson(Map<String, dynamic> j) => EffectsState(
        speed: (j['speed'] as num?)?.toDouble() ?? 1.0,
        pitch: (j['pitch'] as num?)?.toDouble() ?? 1.0,
        boostPercent: (j['boost'] as num?)?.toDouble() ?? 100,
        eqEnabled: j['eqEnabled'] as bool? ?? false,
        eqGains: [
          for (final g in (j['eqGains'] as List? ?? const [0, 0, 0, 0, 0]))
            (g as num).toDouble(),
        ],
        presetName: j['preset'] as String? ?? 'Flat',
        customPresets: {
          for (final e in ((j['custom'] as Map?) ?? const {}).entries)
            e.key as String: [
              for (final g in e.value as List) (g as num).toDouble(),
            ],
        },
      );

  final double speed;
  final double pitch;
  final double boostPercent;
  final bool eqEnabled;
  final List<double> eqGains;
  final String presetName;
  final Map<String, List<double>> customPresets;

  EffectsState copyWith({
    double? speed,
    double? pitch,
    double? boostPercent,
    bool? eqEnabled,
    List<double>? eqGains,
    String? presetName,
    Map<String, List<double>>? customPresets,
  }) =>
      EffectsState(
        speed: speed ?? this.speed,
        pitch: pitch ?? this.pitch,
        boostPercent: boostPercent ?? this.boostPercent,
        eqEnabled: eqEnabled ?? this.eqEnabled,
        eqGains: eqGains ?? this.eqGains,
        presetName: presetName ?? this.presetName,
        customPresets: customPresets ?? this.customPresets,
      );

  Map<String, dynamic> toJson() => {
        'speed': speed,
        'pitch': pitch,
        'boost': boostPercent,
        'eqEnabled': eqEnabled,
        'eqGains': eqGains,
        'preset': presetName,
        'custom': customPresets,
      };
}
