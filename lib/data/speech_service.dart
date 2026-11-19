import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../domain/models.dart';

/// The narrator. Every spoken word goes through here, so system speech can be
/// swapped for recordings without touching the UI.
class SpeechService {
  final _tts = FlutterTts();
  bool _ok = false;
  int _token = 0;

  /// True while speaking; drives the mascot's beak.
  final talking = ValueNotifier(false);

  /// Languages with an installed system voice.
  final available = <Lang>{};

  static const _locale = {Lang.pl: 'pl-PL', Lang.en: 'en-GB'};

  Future<void> init() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.42); // a little slower than default, for children
      for (final l in Lang.values) {
        if (await _tts.isLanguageAvailable(_locale[l]!) == true) available.add(l);
      }
      // English falls back to en-US where en-GB is missing.
      if (!available.contains(Lang.en) && await _tts.isLanguageAvailable('en-US') == true) {
        available.add(Lang.en);
        _enLocale = 'en-US';
      }
      _ok = true;
    } catch (_) {
      _ok = false; // no speech engine (or tests): the app stays usable with text
    }
  }

  String _enLocale = 'en-GB';

  /// Speaks each part in its own language's voice, in order. A new call
  /// interrupts the previous one. Names are never read by the wrong voice.
  Future<void> say(List<(String, Lang)> parts) async {
    final token = ++_token;
    if (!_ok) return;
    try {
      await _tts.stop();
      talking.value = true;
      for (var i = 0; i < parts.length; i++) {
        final (text, lang) = parts[i];
        if (!available.contains(lang)) continue;
        if (i > 0) await Future<void>.delayed(const Duration(milliseconds: 400));
        if (token != _token) return;
        await _tts.setLanguage(lang == Lang.en ? _enLocale : _locale[lang]!);
        await _tts.speak(text);
        if (token != _token) return;
      }
    } catch (_) {
      // Speech is an aid; a failing engine must not break the round.
    } finally {
      if (token == _token) talking.value = false;
    }
  }

  Future<void> stop() async {
    _token++;
    talking.value = false;
    if (_ok) {
      try {
        await _tts.stop();
      } catch (_) {}
    }
  }
}
