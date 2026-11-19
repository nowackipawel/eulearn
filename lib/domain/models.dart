/// Pure Dart game model. No Flutter imports: this layer must stay runnable
/// on a server for multiplayer scoring.
library;

enum Skill { location, shape, flag, capital }

enum Lang {
  pl,
  en;

  Lang get other => this == pl ? en : pl;
}

enum RoundMode { daily, find, flags, capitals, neighbors, puzzle, listen }

/// Leitner box for one country–skill pair. Level 0 = never seen.
class Mastery {
  const Mastery(this.level, [this.due]);
  final int level;
  final DateTime? due;

  static const none = Mastery(0);

  List<Object?> toJson() => [level, due?.toIso8601String()];
  factory Mastery.fromJson(List<dynamic> j) =>
      Mastery(j[0] as int, j[1] == null ? null : DateTime.parse(j[1] as String));
}

/// How far a country is on the map: drives fill pattern and border ribbon.
enum Stage { unseen, fresh, learning, known }

class Progress {
  const Progress([this.items = const {}]);
  final Map<String, Map<Skill, Mastery>> items;

  Mastery of(String code, Skill skill) => items[code]?[skill] ?? Mastery.none;

  bool seen(String code) => items[code]?.values.any((m) => m.level > 0) ?? false;

  /// Skills at level 3+; each closes a quarter of the border ribbon.
  int skillsKnown(String code) =>
      Skill.values.where((s) => of(code, s).level >= 3).length;

  Stage stage(String code) {
    if (!seen(code)) return Stage.unseen;
    final n = skillsKnown(code);
    return n == 4 ? Stage.known : (n >= 2 ? Stage.learning : Stage.fresh);
  }

  int get knownCount => items.keys.where((c) => stage(c) == Stage.known).length;

  Progress withMastery(String code, Skill skill, Mastery m) => Progress({
        ...items,
        code: {...?items[code], skill: m},
      });

  Map<String, dynamic> toJson() => {
        for (final e in items.entries)
          e.key: {for (final s in e.value.entries) s.key.name: s.value.toJson()},
      };

  factory Progress.fromJson(Map<String, dynamic> j) => Progress({
        for (final e in j.entries)
          e.key: {
            for (final s in (e.value as Map<String, dynamic>).entries)
              Skill.values.byName(s.key): Mastery.fromJson(s.value as List<dynamic>),
          },
      });
}

/// The slice of geography the game logic needs.
class CountryNode {
  const CountryNode({
    required this.code,
    required this.neighbors,
    this.near = const [],
    this.similarFlags = const [],
  });
  final String code;
  final List<String> neighbors;
  final List<String> near;
  final List<String> similarFlags;

  /// Land neighbours, or the closest countries for islands.
  List<String> get around => neighbors.isNotEmpty ? neighbors : near;
}

sealed class Question {
  const Question(this.code, this.skill, {this.otherLang = false});
  final String code;
  final Skill skill;

  /// Prompt is spoken in the second language with no text ("listen" items).
  final bool otherLang;

  /// Intro cards are not scored.
  bool get scored => true;
}

/// Shows a new country before it is asked about.
class IntroCard extends Question {
  const IntroCard(String code) : super(code, Skill.location);
  @override
  bool get scored => false;
}

/// Tap the country on the map. [byCapital]: the prompt names the capital.
class TapOnMapQuestion extends Question {
  const TapOnMapQuestion(super.code, super.skill, {this.byCapital = false, super.otherLang});
  final bool byCapital;
}

enum ChoiceKind { flagOfCountry, countryOfFlag, capitalOfCountry }

/// Pick one of [options] (country codes; the UI shows flags or names).
class ChoiceQuestion extends Question {
  const ChoiceQuestion(super.code, super.skill, this.kind, this.options, {super.otherLang});
  final ChoiceKind kind;
  final List<String> options;
}

/// Tap every neighbour of [code].
class NeighborsQuestion extends Question {
  const NeighborsQuestion(String code, this.answers) : super(code, Skill.shape);
  final List<String> answers;
}

/// Put the [pieces] back on the map.
class PlacePiecesQuestion extends Question {
  PlacePiecesQuestion(this.pieces) : super(pieces.first, Skill.shape);
  final List<String> pieces;
}

class Answer {
  const Answer({required this.playerId, required this.correct, this.hinted = false});
  final String playerId;
  final bool correct;
  final bool hinted;
}

/// One round. Deterministic: same seed + same answers = same result, so every
/// multiplayer client can compute the score independently.
class GameSession {
  const GameSession({
    required this.seed,
    required this.questions,
    required this.playerIds,
    this.index = 0,
    this.attempts = 0,
    this.hinted = false,
    this.firstTry = const {},
  });

  final int seed;
  final List<Question> questions;
  final List<String> playerIds;
  final int index;

  /// Wrong attempts on the current question.
  final int attempts;
  final bool hinted;

  /// Per player: indexes of questions solved first try, without a hint.
  final Map<String, Set<int>> firstTry;

  bool get finished => index >= questions.length;
  Question get current => questions[index];
  int get scoredCount => questions.where((q) => q.scored).length;

  /// A hint is offered after the second wrong attempt.
  bool get hintDue => attempts >= 2;

  GameSession apply(Answer a) {
    if (finished) return this;
    if (!a.correct) {
      return _copy(attempts: attempts + 1, hinted: hinted || a.hinted || attempts + 1 >= 2);
    }
    final clean = current.scored && attempts == 0 && !hinted && !a.hinted;
    return GameSession(
      seed: seed,
      questions: questions,
      playerIds: playerIds,
      index: index + 1,
      firstTry: clean
          ? {
              ...firstTry,
              a.playerId: {...?firstTry[a.playerId], index}
            }
          : firstTry,
    );
  }

  int score(String playerId) => firstTry[playerId]?.length ?? 0;

  /// 1–3 stars from the share of clean answers.
  int stars(String playerId) {
    if (scoredCount == 0) return 3;
    final r = score(playerId) / scoredCount;
    return r >= 0.85 ? 3 : (r >= 0.5 ? 2 : 1);
  }

  GameSession _copy({int? attempts, bool? hinted}) => GameSession(
        seed: seed,
        questions: questions,
        playerIds: playerIds,
        index: index,
        attempts: attempts ?? this.attempts,
        hinted: hinted ?? this.hinted,
        firstTry: firstTry,
      );
}
