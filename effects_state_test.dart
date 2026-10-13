import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_ation/features/effects/effects_state.dart';

void main() {
  test('boostDb: 100% is 0 dB, 300% is ~9.54 dB', () {
    expect(boostDb(100), 0);
    expect(boostDb(50), 0);
    expect(boostDb(300), closeTo(9.542, 0.01));
    expect(boostDb(200), closeTo(6.02, 0.01));
  });

  test('resampleCurve keeps endpoints and requested length', () {
    final r = resampleCurve([0, 10], 5);
    expect(r.length, 5);
    expect(r.first, 0);
    expect(r.last, 10);
    expect(r[2], closeTo(5, 1e-9));
  });

  test('resampleCurve identity and empty', () {
    expect(resampleCurve([1, 2, 3], 3), [1, 2, 3]);
    expect(resampleCurve([], 4), [0, 0, 0, 0]);
  });

  test('EffectsState json round trip', () {
    const s = EffectsState(
      speed: 0.85,
      boostPercent: 250,
      eqEnabled: true,
      eqGains: [1, 2, 3, 4, 5],
      presetName: 'X',
      customPresets: {'X': [1, 2, 3, 4, 5]},
    );
    final r = EffectsState.fromJson(s.toJson());
    expect(r.speed, 0.85);
    expect(r.boostPercent, 250);
    expect(r.eqGains, [1, 2, 3, 4, 5]);
    expect(r.customPresets['X'], [1, 2, 3, 4, 5]);
  });

  test('all built-in presets have 5 points', () {
    for (final e in kEqPresets.entries) {
      expect(e.value.length, 5, reason: e.key);
    }
  });
}
