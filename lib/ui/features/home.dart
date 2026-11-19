import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models.dart';
import '../../domain/question_factory.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../core/map/geo_map.dart';
import '../core/map_screen.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

/// Start: the map is both the backdrop and the progress display.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeState();
}

class _HomeState extends ConsumerState<HomeScreen> {
  final _map = GeoMapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = ref.read(profilesProvider).active;
      if (p == null) return;
      final geo = ref.read(geoProvider);
      _map.focusOn(activePool(learningOrder(geo.graph, p.home), p.progress));
    });
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profilesProvider).active;
    if (p == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    final geo = ref.watch(geoProvider);
    return MapScreen(
      controller: _map,
      styleOf: (c) => progressStyle(p, c),
      labelOf: (c) => p.progress.seen(c) || c == p.home ? geo.text(c, p.lang).name : null,
      showBack: false,
      interactive: false,
      left: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: AppPanel(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(children: [
                FlagImage(p.home, height: 30),
                const SizedBox(width: 10),
                Expanded(child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Tok.display(24))),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          AppButton(icon: Icons.lock_rounded, semanticLabel: l.parents, onTap: () => context.push('/parents')),
        ]),
        const Spacer(),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Mascot(talking: ref.watch(speechProvider).talking, size: 76),
          const SizedBox(width: 8),
          Expanded(
            child: AppButton(
              key: const ValueKey('daily'),
              kind: ButtonKind.primary,
              icon: Icons.explore_rounded,
              label: l.dailyJourney,
              fontSize: 28,
              onTap: () => context.push('/round/${RoundMode.daily.name}'),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          for (final (icon, label, path) in [
            (Icons.travel_explore_rounded, l.explorer, '/explorer'),
            (Icons.extension_rounded, l.games, '/games'),
            (Icons.menu_book_rounded, l.passport, '/passport'),
          ]) ...[
            Expanded(child: _Tile(icon: icon, label: label, onTap: () => context.push(path))),
            if (path != '/passport') const SizedBox(width: 10),
          ],
        ]),
      ]),
    );
  }
}

/// Icon over word: children who cannot read still find their way.
class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppButton(
        semanticLabel: label,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 34, color: Tok.ink),
            FittedBox(child: Text(label, style: Tok.display(18))),
          ]),
        ),
      );
}

class GamesScreen extends ConsumerWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profilesProvider).active!;
    final l = AppLocalizations.of(context)!;
    final modes = [
      (RoundMode.find, Icons.place_rounded, l.modeFind),
      (RoundMode.puzzle, Icons.extension_rounded, l.modePuzzle),
      (RoundMode.flags, Icons.flag_rounded, l.modeFlags),
      (RoundMode.capitals, Icons.location_city_rounded, l.modeCapitals),
      (RoundMode.neighbors, Icons.hub_rounded, l.modeNeighbors),
      if (p.secondLang) (RoundMode.listen, Icons.hearing_rounded, l.modeListen),
    ];
    return MapScreen(
      styleOf: (c) => progressStyle(p, c, dim: true),
      interactive: false,
      showLegend: false,
      center: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Tok.touch + Tok.gap),
        child: Wrap(alignment: WrapAlignment.center, spacing: 14, runSpacing: 14, children: [
          for (final (mode, icon, label) in modes)
            SizedBox(
              width: 200,
              child: AppButton(
                key: ValueKey('mode-${mode.name}'),
                semanticLabel: label,
                onTap: () => context.push('/round/${mode.name}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon, size: 44, color: Tok.ink),
                    const SizedBox(height: 4),
                    Text(label, textAlign: TextAlign.center, style: Tok.display(22)),
                  ]),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
