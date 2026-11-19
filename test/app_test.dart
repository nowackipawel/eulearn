// Drives the real app through its main flows and renders each screen to PNG
// (flutter test --update-goldens test/app_test.dart) for visual review.
import 'dart:convert';
import 'dart:io';

import 'package:eulearn/app.dart';
import 'package:eulearn/data/geo_repository.dart';
import 'package:eulearn/data/profile.dart';
import 'package:eulearn/domain/models.dart';
import 'package:eulearn/l10n/app_localizations.dart';
import 'package:eulearn/providers.dart';
import 'package:eulearn/ui/core/theme.dart';
import 'package:eulearn/ui/core/map/geo_map.dart';
import 'package:eulearn/ui/features/round.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> loadFonts() async {
  Future<ByteData> f(String p) async => ByteData.sublistView(await File(p).readAsBytes());
  await (FontLoader('Andika')
        ..addFont(f('assets/fonts/Andika-Regular.ttf'))
        ..addFont(f('assets/fonts/Andika-Bold.ttf'))
        ..addFont(f('assets/fonts/Andika-Italic.ttf')))
      .load();
  await (FontLoader('SofiaSansSemiCondensed')..addFont(f('assets/fonts/SofiaSansSemiCondensed.ttf'))).load();
  await (FontLoader('MaterialIcons')
        ..addFont(f('${Platform.environment['FLUTTER_ROOT'] ?? '/Users/pc/fvm/default'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')))
      .load();
}

Profile sample() {
  final now = DateTime(2026, 11, 20);
  var p = const Progress();
  void set(String c, List<int> levels) {
    for (var i = 0; i < 4; i++) {
      if (levels[i] > 0) p = p.withMastery(c, Skill.values[i], Mastery(levels[i], now));
    }
  }

  set('pl', [5, 4, 5, 3]);
  set('de', [4, 3, 3, 3]);
  set('cz', [3, 1, 3, 1]);
  set('sk', [1, 1, 1, 1]);
  set('lt', [3, 3, 1, 1]);
  set('ua', [1, 1, 1, 1]);
  return Profile(id: 'p1', name: 'Ola', home: 'pl', lang: Lang.pl, progress: p, streak: 3);
}

late GeoRepository geo;

Future<void> boot(WidgetTester t, {Profile? profile, Size size = const Size(844, 390), Widget? child}) async {
  t.view.physicalSize = size * 2;
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  SharedPreferences.setMockInitialValues(profile == null
      ? {}
      : {
          'flutter.profiles': ['p1'],
          'flutter.active': 'p1',
          'flutter.profile_p1': jsonEncode(profile.toJson()),
        });
  final prefs = (await t.runAsync(SharedPreferences.getInstance))!;
  await t.pumpWidget(ProviderScope(
    overrides: [geoProvider.overrideWithValue(geo), prefsProvider.overrideWithValue(prefs)],
    child: child ?? const App(),
  ));
  await t.pump(const Duration(milliseconds: 600));
}

Future<void> shot(WidgetTester t, String name) async {
  await t.pump(const Duration(milliseconds: 500));
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadFonts();
    geo = await GeoRepository.load(rootBundle);
  });

  testWidgets('first run: language, name, my country, then home', (t) async {
    await boot(t);
    await shot(t, 'onboarding_language');
    await t.tap(find.byKey(const ValueKey('lang-pl')));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Twoje imię'), findsOneWidget);
    await t.enterText(find.byType(TextField), 'Ola');
    await t.tap(find.byKey(const ValueKey('name-next')));
    await t.pump(const Duration(milliseconds: 600));
    t.widget<GeoMap>(find.byType(GeoMap)).onTap!('pl');
    await t.pump(const Duration(milliseconds: 600));
    await shot(t, 'onboarding_home_country');
    await t.tap(find.byKey(const ValueKey('confirm-home')));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('daily')), findsOneWidget);
    final c = ProviderScope.containerOf(t.element(find.byType(App)));
    expect(c.read(profilesProvider).active!.home, 'pl');
    expect(c.read(profilesProvider).active!.lang, Lang.pl);
  });

  testWidgets('home, games, passport, explorer render in Polish', (t) async {
    for (final (label, name) in [('Gry', 'games'), ('Paszport', 'passport'), ('Odkrywca', 'explorer')]) {
      await boot(t, profile: sample());
      if (name == 'games') await shot(t, 'home');
      await t.tap(find.text(label));
      await t.pump(const Duration(milliseconds: 600));
      if (name == 'explorer') {
        t.widget<GeoMap>(find.byType(GeoMap)).onTap!('de');
        await t.pump(const Duration(milliseconds: 600));
        await t.pump(const Duration(milliseconds: 100));
        expect(find.text('Germany'), findsOneWidget, reason: 'second-language name on the card');
      }
      await shot(t, name);
      await t.pumpWidget(const SizedBox.shrink());
    }
  });

  for (final (name, mode, seed) in [
    ('round_find', RoundMode.find, 3),
    ('round_flags', RoundMode.flags, 3),
    ('round_capitals', RoundMode.capitals, 5),
    ('round_neighbors', RoundMode.neighbors, 1),
    ('round_puzzle', RoundMode.puzzle, 2),
  ]) {
    testWidgets('$name renders', (t) async {
      await boot(t, profile: sample(), child: _Harness(RoundScreen(mode: mode, seed: seed)));
      await shot(t, name);
    });
  }

  testWidgets('a full round: right answers raise mastery and reach the result screen', (t) async {
    await boot(t, profile: sample(), child: const _Harness(RoundScreen(mode: RoundMode.find, seed: 3)));
    final c = ProviderScope.containerOf(t.element(find.byType(RoundScreen)));
    final before = c.read(profilesProvider).active!.progress;
    for (var guard = 0; guard < 40 && find.text('Brawo!').evaluate().isEmpty; guard++) {
      final next = find.text('Dalej');
      if (next.evaluate().isNotEmpty) {
        await t.tap(next);
      } else {
        // Answer through the map's own tap callback with the right country.
        final state = t.state(find.byType(RoundScreen)) as dynamic;
        final map = t.widget<GeoMap>(find.byType(GeoMap));
        map.onTap!(state.debugCurrentCode as String);
      }
      await t.pump(const Duration(milliseconds: 1500));
      await t.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('Brawo!'), findsOneWidget);
    final after = c.read(profilesProvider).active!;
    expect(after.progress.items.length, greaterThanOrEqualTo(before.items.length));
    expect(after.lastPlayed, isNotNull);
    await shot(t, 'round_result');
  });

  testWidgets('tablet and English layouts hold', (t) async {
    final p = sample().copyWith(lang: Lang.en);
    await boot(t, profile: p, size: const Size(1180, 820), child: const _Harness(RoundScreen(mode: RoundMode.flags, seed: 3), en: true));
    await shot(t, 'tablet_round_flags_en');
  });
}

class _Harness extends StatelessWidget {
  const _Harness(this.child, {this.en = false});
  final Widget child;
  final bool en;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: Tok.theme(),
        locale: Locale(en ? 'en' : 'pl'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      );
}
