import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../domain/models.dart';

/// Name of the recording for a phrase: FNV-1a 64-bit of "lang|text".
/// Must match key() in tool/build_voice.py.
String voiceKey(Lang lang, String text) {
  var h = 0xcbf29ce484222325;
  for (final b in utf8.encode('${lang.name}|$text')) {
    h = (h ^ b) * 0x100000001b3; // wraps at 64 bits on the Dart VM
  }
  return (h >>> 32).toRadixString(16).padLeft(8, '0') + (h & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
}

/// The narrator. Every spoken word goes through here. A phrase is played from
/// its recording (tool/build_voice.py) when one exists for the exact text,
/// and read by the system voice otherwise.
class SpeechService {
  final _tts = FlutterTts();
  AudioPlayer? _player;
  bool _ttsOk = false;
  int _token = 0;
  Completer<void>? _interrupt;

  /// `pl/KEY` for every recorded phrase.
  var _recorded = <String>{};

  /// True while speaking; drives the mascot's beak.
  final talking = ValueNotifier(false);

  /// Languages that can be spoken: recorded, or with an installed system voice.
  final available = <Lang>{};

  static const _locale = {Lang.pl: 'pl-PL', Lang.en: 'en-GB'};
  String _enLocale = 'en-GB';

  Future<void> init() async {
    try {
      _recorded = (jsonDecode(await rootBundle.loadString('assets/audio/voice/index.json')) as List).cast<String>().toSet();
      if (_recorded.isNotEmpty) {
        _player = AudioPlayer();
        await _player!.setAudioContext(AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build());
        for (final l in Lang.values) {
          if (_recorded.any((k) => k.startsWith('${l.name}/'))) available.add(l);
        }
      }
    } catch (_) {
      _player = null; // no recordings or no audio engine: system speech only
      _recorded = {};
    }
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.42); // a little slower than default, for children
      for (final l in Lang.values) {
        if (await _tts.isLanguageAvailable(_locale[l]!) == true) available.add(l);
      }
      // English falls back to en-US where en-GB is missing.
      if (await _tts.isLanguageAvailable('en-GB') != true && await _tts.isLanguageAvailable('en-US') == true) {
        available.add(Lang.en);
        _enLocale = 'en-US';
      }
      _ttsOk = true;
    } catch (_) {
      _ttsOk = false; // no speech engine (or tests): the app stays usable with text
    }
  }

  /// Speaks each part in its own language's voice, in order. A new call
  /// interrupts the previous one. Names are never read by the wrong voice.
  Future<void> say(List<(String, Lang)> parts) async {
    final token = ++_token;
    _interrupt?.complete();
    final interrupt = _interrupt = Completer<void>();
    try {
      await _player?.stop();
      if (_ttsOk) await _tts.stop();
      talking.value = true;
      for (var i = 0; i < parts.length; i++) {
        final (text, lang) = parts[i];
        final clip = '${lang.name}/${voiceKey(lang, text)}';
        final recorded = _player != null && _recorded.contains(clip);
        if (!recorded && !(_ttsOk && available.contains(lang))) continue;
        if (i > 0) await Future<void>.delayed(const Duration(milliseconds: 400));
        if (token != _token) return;
        if (recorded) {
          final done = _player!.onPlayerComplete.first;
          await _player!.play(AssetSource('audio/voice/$clip.mp3'));
          await Future.any([done, interrupt.future, Future<void>.delayed(const Duration(seconds: 20))]);
        } else {
          await _tts.setLanguage(lang == Lang.en ? _enLocale : _locale[lang]!);
          await _tts.speak(text);
        }
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
    _interrupt?.complete();
    _interrupt = null;
    talking.value = false;
    try {
      await _player?.stop();
      if (_ttsOk) await _tts.stop();
    } catch (_) {}
  }
}
