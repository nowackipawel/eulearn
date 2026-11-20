import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.home,
    required this.lang,
    required this.region,
    this.avatar = 0,
    this.secondLang = true,
    this.readAloud = true,
    this.sfx = true,
    this.progress = const Progress(),
    this.streak = 0,
    this.lastPlayed,
  });

  final String id;
  final String name;
  final int avatar;

  /// "My country".
  final String home;
  final Lang lang;

  /// Continent the child is learning now.
  final String region;

  /// Also speak names in the other language.
  final bool secondLang;
  final bool readAloud;

  /// Sound effects on.
  final bool sfx;
  final Progress progress;
  final int streak;

  /// Day of the last finished round (date only).
  final DateTime? lastPlayed;

  static const schema = 1;

  Profile copyWith({
    String? name,
    String? home,
    Lang? lang,
    String? region,
    bool? secondLang,
    bool? readAloud,
    bool? sfx,
    Progress? progress,
    int? streak,
    DateTime? lastPlayed,
  }) =>
      Profile(
        id: id,
        avatar: avatar,
        name: name ?? this.name,
        home: home ?? this.home,
        lang: lang ?? this.lang,
        region: region ?? this.region,
        secondLang: secondLang ?? this.secondLang,
        readAloud: readAloud ?? this.readAloud,
        sfx: sfx ?? this.sfx,
        progress: progress ?? this.progress,
        streak: streak ?? this.streak,
        lastPlayed: lastPlayed ?? this.lastPlayed,
      );

  /// Call when a round is finished: keeps the day streak.
  Profile played(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (lastPlayed == today) return this;
    final yesterday = today.subtract(const Duration(days: 1));
    return copyWith(streak: lastPlayed == yesterday ? streak + 1 : 1, lastPlayed: today);
  }

  Map<String, dynamic> toJson() => {
        'schema': schema,
        'id': id,
        'name': name,
        'avatar': avatar,
        'home': home,
        'lang': lang.name,
        'region': region,
        'secondLang': secondLang,
        'readAloud': readAloud,
        'sfx': sfx,
        'streak': streak,
        'lastPlayed': lastPlayed?.toIso8601String(),
        'mastery': progress.toJson(),
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        name: j['name'] as String,
        avatar: j['avatar'] as int? ?? 0,
        home: j['home'] as String,
        lang: Lang.values.byName(j['lang'] as String),
        // Profiles saved before other continents existed were all in Europe.
        region: j['region'] as String? ?? 'europe',
        secondLang: j['secondLang'] as bool? ?? true,
        readAloud: j['readAloud'] as bool? ?? true,
        sfx: j['sfx'] as bool? ?? true,
        streak: j['streak'] as int? ?? 0,
        lastPlayed: j['lastPlayed'] == null ? null : DateTime.parse(j['lastPlayed'] as String),
        progress: Progress.fromJson(j['mastery'] as Map<String, dynamic>? ?? const {}),
      );
}

/// Profiles live on the device only, one JSON entry each.
class ProfileStore {
  ProfileStore(this._prefs);
  final SharedPreferences _prefs;

  static const maxProfiles = 4;

  String? get activeId => _prefs.getString('active');
  Future<void> setActive(String? id) => id == null ? _prefs.remove('active') : _prefs.setString('active', id);

  List<Profile> loadAll() {
    final out = <Profile>[];
    for (final id in _prefs.getStringList('profiles') ?? const <String>[]) {
      final raw = _prefs.getString('profile_$id');
      if (raw == null) continue;
      try {
        out.add(Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {
        // Never lose a child's progress silently: keep the unreadable entry
        // so it can be recovered, and skip it.
        _prefs.setString('corrupt_$id', raw);
      }
    }
    return out;
  }

  Future<void> save(Profile p) async {
    final ids = _prefs.getStringList('profiles') ?? <String>[];
    if (!ids.contains(p.id)) await _prefs.setStringList('profiles', [...ids, p.id]);
    await _prefs.setString('profile_${p.id}', jsonEncode(p.toJson()));
  }

  Future<void> delete(String id) async {
    final ids = _prefs.getStringList('profiles') ?? <String>[];
    await _prefs.setStringList('profiles', ids.where((i) => i != id).toList());
    await _prefs.remove('profile_$id');
  }
}
