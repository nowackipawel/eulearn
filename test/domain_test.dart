import 'dart:convert';
import 'dart:io';

import 'package:eulearn/domain/leitner.dart';
import 'package:eulearn/domain/models.dart';
import 'package:eulearn/domain/question_factory.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, CountryNode> loadGraph() {
  final j = jsonDecode(File('assets/geo/countries.json').readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final e in j.entries)
      e.key: CountryNode(
        code: e.key,
        neighbors: (e.value['neighbors'] as List).cast(),
        near: (e.value['near'] as List).cast(),
        similarFlags: (e.value['similarFlags'] as List).cast(),
      ),
  };
}

void main() {
  final now = DateTime(2026, 11, 20);
  final graph = loadGraph();

  test('leitner: promote raises level and schedules, demote resets to 1', () {
    var m = promote(Mastery.none, now);
    expect(m.level, 1);
    expect(isDue(m, now), isTrue);
    m = promote(promote(m, now), now);
    expect(m.level, 3);
    expect(m.due, now.add(const Duration(days: 3)));
    expect(isDue(m, now), isFalse);
    expect(isDue(m, now.add(const Duration(days: 3))), isTrue);
    expect(demote(m, now).level, 1);
    expect(promote(const Mastery(5), now).level, 5);
  });

  test('learning order starts at home, then neighbours, covers everything', () {
    final o = learningOrder(graph, 'pl');
    expect(o.first, 'pl');
    expect(o.sublist(1, 8).toSet(), graph['pl']!.neighbors.toSet());
    expect(o.toSet(), graph.keys.toSet());
    expect(o.length, graph.length);
  });

  test('rounds are deterministic for a seed and well formed', () {
    for (final mode in RoundMode.values) {
      List<Question> build(int seed) => buildRound(
          mode: mode, graph: graph, home: 'pl', progress: const Progress(), seed: seed, now: now);
      String sig(List<Question> qs) => qs.map((q) => '${q.runtimeType}:${q.code}:${q.skill}').join(',');
      final a = build(7);
      expect(sig(a), sig(build(7)), reason: '$mode');
      if (mode != RoundMode.listen) expect(a, isNotEmpty, reason: '$mode');
      for (final q in a) {
        if (q is ChoiceQuestion) {
          expect(q.options, contains(q.code));
          expect(q.options.toSet().length, q.options.length);
          expect(q.options.length, 3);
        }
      }
    }
  });

  test('a new child is introduced to a country before being asked about it', () {
    final qs = buildRound(
        mode: RoundMode.daily, graph: graph, home: 'pl', progress: const Progress(), seed: 1, now: now);
    final met = <String>{};
    for (final q in qs) {
      if (q is IntroCard) {
        met.add(q.code);
      } else {
        expect(met, contains(q.code));
      }
    }
    expect(met, contains('pl'), reason: 'home country comes first');
  });

  test('second-language prompts only for pairs at level 3+, and only when enabled', () {
    var p = const Progress();
    for (final c in ['pl', 'de', 'cz', 'sk', 'ua']) {
      for (final s in Skill.values) {
        p = p.withMastery(c, s, Mastery(c == 'pl' ? 4 : 1, now));
      }
    }
    for (var seed = 0; seed < 40; seed++) {
      final on = buildRound(
          mode: RoundMode.daily, graph: graph, home: 'pl', progress: p, seed: seed, now: now);
      for (final q in on.where((q) => q.otherLang)) {
        expect(p.of(q.code, q.skill).level, greaterThanOrEqualTo(3));
      }
      final off = buildRound(
          mode: RoundMode.daily, graph: graph, home: 'pl', progress: p, seed: seed, now: now, secondLang: false);
      expect(off.any((q) => q.otherLang), isFalse);
    }
  });

  test('session: clean answers score, hints and retries do not', () {
    final qs = <Question>[
      const IntroCard('pl'),
      const TapOnMapQuestion('pl', Skill.location),
      const TapOnMapQuestion('de', Skill.location),
    ];
    var s = GameSession(seed: 1, questions: qs, playerIds: const ['a']);
    const ok = Answer(playerId: 'a', correct: true), bad = Answer(playerId: 'a', correct: false);
    s = s.apply(ok); // intro, not scored
    s = s.apply(ok); // clean
    s = s.apply(bad);
    expect(s.hintDue, isFalse);
    s = s.apply(bad);
    expect(s.hintDue, isTrue);
    s = s.apply(ok);
    expect(s.finished, isTrue);
    expect(s.score('a'), 1);
    expect(s.scoredCount, 2);
    expect(s.stars('a'), 2);
  });

  test('record: intro unlocks, clean promotes, miss demotes; progress survives json', () {
    var p = record(const Progress(), const IntroCard('pl'), clean: true, now: now);
    expect(p.stage('pl'), Stage.fresh);
    const q = TapOnMapQuestion('pl', Skill.location);
    p = record(record(p, q, clean: true, now: now), q, clean: true, now: now);
    expect(p.of('pl', Skill.location).level, 3);
    expect(p.skillsKnown('pl'), 1);
    p = record(p, q, clean: false, now: now);
    expect(p.of('pl', Skill.location).level, 1);
    final back = Progress.fromJson(jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>);
    expect(back.of('pl', Skill.location).level, 1);
    expect(back.of('pl', Skill.flag).due, now);
  });

  test('data: neighbours symmetric and differently coloured, content complete in both languages', () {
    final c = jsonDecode(File('assets/geo/countries.json').readAsStringSync()) as Map<String, dynamic>;
    final v = (jsonDecode(File('assets/geo/view_europe.json').readAsStringSync())['countries']) as Map<String, dynamic>;
    final pl = jsonDecode(File('assets/i18n/geo_pl.json').readAsStringSync()) as Map<String, dynamic>;
    final en = jsonDecode(File('assets/i18n/geo_en.json').readAsStringSync()) as Map<String, dynamic>;
    expect(c.length, 46);
    for (final e in c.entries) {
      final code = e.key;
      for (final n in e.value['neighbors'] as List) {
        expect(c[n]['neighbors'], contains(code), reason: '$code-$n');
        expect(c[n]['color'], isNot(e.value['color']), reason: '$code-$n colour');
      }
      expect(v[code]['capital'], isNotNull, reason: code);
      expect(File('assets/flags/$code.svg').existsSync(), isTrue, reason: code);
      for (final k in ['name', 'nameAcc', 'nameGen', 'capital']) {
        expect(pl[code][k], isA<String>(), reason: 'pl $code $k');
      }
      for (final k in ['name', 'capital']) {
        expect(en[code][k], isA<String>(), reason: 'en $code $k');
      }
      for (final s in e.value['similarFlags'] as List) {
        expect(c.containsKey(s), isTrue, reason: '$code similar $s');
      }
    }
  });
}
