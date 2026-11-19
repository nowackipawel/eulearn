import 'models.dart';

/// Days until the next review, by level.
const intervals = [0, 0, 1, 3, 7, 21];

Mastery promote(Mastery m, DateTime now) {
  final level = m.level >= 5 ? 5 : m.level + 1;
  return Mastery(level, now.add(Duration(days: intervals[level])));
}

/// A wrong answer sends the pair back to level 1, due again today.
Mastery demote(Mastery m, DateTime now) => Mastery(1, now);

/// First meeting (intro card) moves a pair from 0 to 1 without a test.
Mastery introduce(Mastery m, DateTime now) => m.level > 0 ? m : Mastery(1, now);

bool isDue(Mastery m, DateTime now) => m.level > 0 && !(m.due?.isAfter(now) ?? false);
