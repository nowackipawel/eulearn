import 'package:audioplayers/audioplayers.dart';

enum Sfx { tap, good, miss, snap, ribbon, stamp, fanfare }

/// Short sound effects (synthesised by tool/build_sfx.py). They mix with the
/// narrator instead of interrupting it.
class SfxService {
  final _pools = <Sfx, AudioPool>{};

  /// Follows the active profile's setting.
  bool enabled = true;

  Future<void> init() async {
    try {
      final ctx = AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build();
      for (final s in Sfx.values) {
        _pools[s] = await AudioPool.create(
          source: AssetSource('audio/sfx/${s.name}.wav'),
          maxPlayers: 2,
          audioContext: ctx,
        );
      }
    } catch (_) {
      _pools.clear(); // no audio engine (or tests): the app stays silent, not broken
    }
  }

  void play(Sfx s) {
    if (!enabled) return;
    _pools[s]?.start().catchError((_) => () async {});
  }
}
