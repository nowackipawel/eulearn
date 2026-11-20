import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'domain/models.dart';
import 'l10n/app_localizations.dart';
import 'providers.dart';
import 'ui/core/theme.dart';
import 'ui/features/continents.dart';
import 'ui/features/explorer.dart';
import 'ui/features/home.dart';
import 'ui/features/onboarding.dart';
import 'ui/features/parent_zone.dart';
import 'ui/features/passport.dart';
import 'ui/features/round.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});
  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  final _refresh = ValueNotifier(0);
  late final _router = GoRouter(
    refreshListenable: _refresh,
    // No profile yet: everything leads to onboarding.
    redirect: (context, state) {
      final has = ref.read(profilesProvider).active != null;
      if (!has && state.matchedLocation != '/onboarding') return '/onboarding';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/continents', builder: (_, _) => const ContinentsScreen()),
      GoRoute(path: '/games', builder: (_, _) => const GamesScreen()),
      GoRoute(path: '/explorer', builder: (_, _) => const ExplorerScreen()),
      GoRoute(path: '/passport', builder: (_, _) => const PassportScreen()),
      GoRoute(path: '/parents', builder: (_, _) => const ParentZoneScreen()),
      GoRoute(
        path: '/round/:mode',
        builder: (_, s) => RoundScreen(mode: RoundMode.values.byName(s.pathParameters['mode']!)),
      ),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    _refresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(profilesProvider.select((s) => s.active == null), (_, _) => _refresh.value++);
    ref.watch(sfxProvider).enabled = ref.watch(profilesProvider.select((s) => s.active?.sfx)) ?? true;
    final lang = ref.watch(profilesProvider.select((s) => s.active?.lang)) ?? ref.watch(pendingLangProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (c) => AppLocalizations.of(c)!.appTitle,
      theme: Tok.theme(),
      routerConfig: _router,
      locale: lang == null ? null : Locale(lang.name),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Follow the system text size, but never past the point layouts break.
      builder: (context, child) => MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, child: child!),
    );
  }
}
