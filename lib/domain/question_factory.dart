import 'dart:math';

import 'leitner.dart';
import 'models.dart';

/// Countries ordered "from my home outwards": breadth-first over borders
/// (nearest countries for islands), ties broken by code. With a [region],
/// only its countries are returned; when home lies elsewhere the walk starts
/// at the region's [anchor].
List<String> learningOrder(Map<String, CountryNode> graph, String home, {Set<String>? region, String? anchor}) {
  final start = region == null || region.contains(home) ? home : (anchor ?? (region.toList()..sort()).first);
  final order = <String>[];
  final seen = <String>{start};
  var frontier = [start];
  while (frontier.isNotEmpty) {
    frontier.sort();
    order.addAll(frontier);
    final next = <String>[];
    for (final c in frontier) {
      for (final n in graph[c]?.around ?? const <String>[]) {
        if (graph.containsKey(n) && seen.add(n)) next.add(n);
      }
    }
    frontier = next;
  }
  // Countries not reachable over borders (other islands) come last.
  order.addAll((graph.keys.where((c) => !seen.contains(c)).toList()..sort()));
  return region == null ? order : order.where(region.contains).toList();
}

/// Countries currently in play: everything already seen plus a few new ones.
List<String> activePool(List<String> order, Progress p, {int fresh = 3, int minimum = 5}) {
  final seen = order.where(p.seen).length;
  return order.take(max(minimum, seen + fresh)).toList();
}

List<Question> buildRound({
  required RoundMode mode,
  required Map<String, CountryNode> graph,
  required String home,
  required Progress progress,
  required int seed,
  required DateTime now,
  Set<String>? region,
  String? anchor,
  bool secondLang = true,
  int count = 8,
}) {
  final rng = Random(seed);
  final order = learningOrder(graph, home, region: region, anchor: anchor);
  final pool = activePool(order, progress);
  final b = _Builder(graph, order, pool, progress, rng, now, secondLang);

  final skills = switch (mode) {
    RoundMode.find => [Skill.location],
    RoundMode.flags => [Skill.flag],
    RoundMode.capitals => [Skill.capital],
    RoundMode.listen => [Skill.location, Skill.flag],
    RoundMode.daily => [Skill.location, Skill.flag, Skill.capital],
    RoundMode.neighbors || RoundMode.puzzle => const <Skill>[],
  };

  if (mode == RoundMode.neighbors) {
    final cs = pool.where((c) => graph[c]!.neighbors.isNotEmpty).take(count ~/ 2).toList();
    return [for (final c in cs) NeighborsQuestion(c, graph[c]!.neighbors)];
  }
  if (mode == RoundMode.puzzle) {
    final cs = [...pool]..shuffle(rng);
    final out = <Question>[];
    for (var i = 0; i < cs.length && out.length < 4; i += 3) {
      out.add(PlacePiecesQuestion(cs.sublist(i, min(i + 3, cs.length))));
    }
    return out;
  }

  // Pairs to practise: overdue first, then new, then weakest.
  final pairs = [for (final c in pool) for (final s in skills) (c, s)];
  int rank((String, Skill) x) {
    final m = progress.of(x.$1, x.$2);
    if (isDue(m, now)) return 0;
    if (m.level == 0) return 1;
    return 2 + m.level;
  }

  pairs.shuffle(rng);
  if (mode == RoundMode.listen) {
    // Listening only makes sense for countries the child has already met.
    pairs.retainWhere((x) => progress.seen(x.$1));
  }
  // Stable sort keeps the seeded shuffle within each rank; position in the
  // learning order decides between new pairs so the map grows outwards.
  final indexed = pairs.indexed.toList()
    ..sort((a, c) {
      final r = rank(a.$2).compareTo(rank(c.$2));
      if (r != 0) return r;
      if (rank(a.$2) == 1) {
        final o = order.indexOf(a.$2.$1).compareTo(order.indexOf(c.$2.$1));
        if (o != 0) return o;
      }
      return a.$1.compareTo(c.$1);
    });
  final chosen = <(String, Skill)>[];
  final perCountry = <String, int>{};
  for (final (_, x) in indexed) {
    if (chosen.length >= count) break;
    // At most two questions about one country per round.
    if ((perCountry[x.$1] ?? 0) >= 2) continue;
    perCountry[x.$1] = (perCountry[x.$1] ?? 0) + 1;
    chosen.add(x);
  }
  chosen.shuffle(rng);
  // Review first, then new countries in learning order, so the map grows
  // outwards from home instead of jumping around.
  int slot((String, Skill) x) => progress.seen(x.$1) ? -1 : order.indexOf(x.$1);
  final sorted = chosen.indexed.toList()
    ..sort((a, c) {
      final d = slot(a.$2).compareTo(slot(c.$2));
      return d != 0 ? d : a.$1.compareTo(c.$1);
    });
  chosen
    ..clear()
    ..addAll(sorted.map((e) => e.$2));

  final out = <Question>[];
  final introduced = <String>{};
  for (final (code, skill) in chosen) {
    if (!progress.seen(code) && introduced.add(code)) out.add(IntroCard(code));
    out.add(b.question(code, skill, forceOther: mode == RoundMode.listen));
  }
  return out;
}

class _Builder {
  _Builder(this.graph, this.order, this.pool, this.progress, this.rng, this.now, this.secondLang);
  final Map<String, CountryNode> graph;
  final List<String> order, pool;
  final Progress progress;
  final Random rng;
  final DateTime now;
  final bool secondLang;

  Question question(String code, Skill skill, {bool forceOther = false}) {
    final level = progress.of(code, skill).level;
    // From level 3 some prompts come in the second language.
    final other = forceOther || (secondLang && level >= 3 && rng.nextInt(3) == 0);
    switch (skill) {
      case Skill.location || Skill.shape:
        return TapOnMapQuestion(code, Skill.location, otherLang: other);
      case Skill.flag:
        final kind = other || rng.nextBool() ? ChoiceKind.flagOfCountry : ChoiceKind.countryOfFlag;
        return ChoiceQuestion(code, skill, kind, options(code, skill, level), otherLang: other);
      case Skill.capital:
        if (level >= 3 && rng.nextBool()) {
          return TapOnMapQuestion(code, skill, byCapital: true);
        }
        return ChoiceQuestion(code, skill, ChoiceKind.capitalOfCountry, options(code, skill, level));
    }
  }

  /// The correct code plus distractors, shuffled. Three options while the
  /// pair is new, four later; similar flags once the child can cope.
  List<String> options(String code, Skill skill, int level) {
    final n = level >= 3 ? 4 : 3;
    final picks = <String>{code};
    void addFrom(Iterable<String> src) {
      final l = src.where((c) => graph.containsKey(c) && !picks.contains(c)).toList()..shuffle(rng);
      for (final c in l) {
        if (picks.length >= n) return;
        picks.add(c);
      }
    }

    if (skill == Skill.flag && level >= 3) addFrom(graph[code]!.similarFlags);
    addFrom(graph[code]!.around);
    addFrom(pool);
    addFrom(order);
    return picks.toList()..shuffle(rng);
  }
}

/// Applies a finished question to the child's progress.
Progress record(Progress p, Question q, {required bool clean, required DateTime now}) {
  if (q is IntroCard) {
    var out = p;
    for (final s in Skill.values) {
      out = out.withMastery(q.code, s, introduce(out.of(q.code, s), now));
    }
    return out;
  }
  final codes = q is PlacePiecesQuestion ? q.pieces : [q.code];
  var out = p;
  for (final c in codes) {
    final m = out.of(c, q.skill);
    out = out.withMastery(c, q.skill, clean ? promote(m, now) : demote(m, now));
  }
  return out;
}
