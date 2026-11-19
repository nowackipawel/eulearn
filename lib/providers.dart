import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/geo_repository.dart';
import 'data/profile.dart';
import 'data/speech_service.dart';
import 'domain/models.dart';

/// Loaded once in main() before the first frame.
final geoProvider = Provider<GeoRepository>((_) => throw UnimplementedError('override in main'));
final prefsProvider = Provider<SharedPreferences>((_) => throw UnimplementedError('override in main'));
final speechProvider = Provider<SpeechService>((_) => SpeechService());

class ProfilesState {
  const ProfilesState(this.all, this.activeId);
  final List<Profile> all;
  final String? activeId;

  Profile? get active {
    for (final p in all) {
      if (p.id == activeId) return p;
    }
    return null;
  }
}

class ProfilesNotifier extends Notifier<ProfilesState> {
  late final ProfileStore _store;

  @override
  ProfilesState build() {
    _store = ProfileStore(ref.watch(prefsProvider));
    final all = _store.loadAll();
    final id = _store.activeId;
    return ProfilesState(all, all.any((p) => p.id == id) ? id : (all.isEmpty ? null : all.first.id));
  }

  Future<void> create({required String name, required String home, required Lang lang}) async {
    if (state.all.length >= ProfileStore.maxProfiles) return;
    final p = Profile(
      id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      name: name,
      avatar: state.all.length,
      home: home,
      lang: lang,
    );
    state = ProfilesState([...state.all, p], p.id);
    await _store.save(p);
    await _store.setActive(p.id);
  }

  Future<void> save(Profile p) async {
    state = ProfilesState([for (final x in state.all) x.id == p.id ? p : x], state.activeId);
    await _store.save(p);
  }

  Future<void> select(String id) async {
    state = ProfilesState(state.all, id);
    await _store.setActive(id);
  }

  Future<void> remove(String id) async {
    final rest = state.all.where((p) => p.id != id).toList();
    final next = rest.isEmpty ? null : rest.first.id;
    state = ProfilesState(rest, state.activeId == id ? next : state.activeId);
    await _store.delete(id);
    await _store.setActive(state.activeId);
  }
}

final profilesProvider = NotifierProvider<ProfilesNotifier, ProfilesState>(ProfilesNotifier.new);
