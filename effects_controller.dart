import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/player_service.dart';
import '../../core/theme/theme_controller.dart';
import 'effects_state.dart';

final effectsControllerProvider =
    NotifierProvider<EffectsController, EffectsState>(EffectsController.new);

class EffectsController extends Notifier<EffectsState> {
  static const _key = 'effects.v1';

  @override
  EffectsState build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const EffectsState();
    try {
      return EffectsState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const EffectsState();
    }
  }

  Future<void> _commit(EffectsState s) async {
    state = s;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(s.toJson()));
  }

  Future<void> _push(Future<void> Function(PlayerService) f) async {
    try {
      await f(ref.read(playerServiceProvider));
    } catch (e) {
      debugPrint('Effect could not be applied: $e');
    }
  }

  Future<void> setSpeed(double v) async {
    await _commit(state.copyWith(speed: v));
    await _push((s) => s.player.setSpeed(v));
  }

  Future<void> setPitch(double v) async {
    await _commit(state.copyWith(pitch: v));
    await _push((s) => s.player.setPitch(v));
  }

  Future<void> setBoost(double percent) async {
    await _commit(state.copyWith(boostPercent: percent));
    await _push((s) => s.setBoostPercent(percent));
  }

  /// "Slowed": lowers speed and pitch together (vinyl-style). No reverb yet.
  Future<void> applySlowed() async {
    await _commit(state.copyWith(speed: 0.85, pitch: 0.85));
    await _push((s) async {
      await s.player.setSpeed(0.85);
      await s.player.setPitch(0.85);
    });
  }

  Future<void> setEqGain(int band, int bandCount, double v) async {
    final g = resampleCurve(state.eqGains, bandCount);
    g[band] = v;
    await _commit(
      state.copyWith(eqGains: g, eqEnabled: true, presetName: 'Custom'),
    );
    await _push((s) => s.applyEq(g, true));
  }

  Future<void> applyPreset(String name) async {
    final curve = kEqPresets[name] ?? state.customPresets[name];
    if (curve == null) return;
    await _commit(
      state.copyWith(eqGains: curve, eqEnabled: true, presetName: name),
    );
    await _push((s) => s.applyEq(curve, true));
  }

  Future<void> saveCustomPreset(String name, int bandCount) async {
    final n = name.trim();
    if (n.isEmpty || kEqPresets.containsKey(n)) return;
    final curve = resampleCurve(state.eqGains, bandCount);
    await _commit(
      state.copyWith(
        customPresets: {...state.customPresets, n: curve},
        presetName: n,
      ),
    );
  }

  Future<void> resetAll() async {
    await _commit(const EffectsState());
    await _push((s) => s.applyEffects(const EffectsState()));
  }
}
