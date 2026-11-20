import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/geo_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../core/map/geo_map.dart';
import '../core/map_screen.dart';
import '../core/widgets.dart';

/// The world map: touch any country to pick its continent to learn.
class ContinentsScreen extends ConsumerStatefulWidget {
  const ContinentsScreen({super.key});
  @override
  ConsumerState<ContinentsScreen> createState() => _ContinentsState();
}

class _ContinentsState extends ConsumerState<ContinentsScreen> {
  final _map = GeoMapController();
  late String _region = ref.read(profilesProvider).active!.region;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  void _pick(String code) {
    final p = ref.read(profilesProvider).active!;
    final region = ref.read(geoProvider).continent[code]!;
    setState(() => _region = region);
    ref.read(speechProvider).say([(continentName(AppLocalizations.of(context)!, region), p.lang)]);
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profilesProvider).active!;
    final geo = ref.watch(geoProvider);
    final l = AppLocalizations.of(context)!;
    final name = continentName(l, _region);
    return MapScreen(
      view: GeoRepository.world,
      controller: _map,
      markers: false,
      // The chosen continent in full colour, the rest faded.
      styleOf: (c) => CountryStyle(home: c == p.home, dim: geo.continent[c] != _region),
      onTap: _pick,
      top: PromptBar(text: name, onSpeak: () => ref.read(speechProvider).say([(name, p.lang)])),
      center: Align(
        alignment: Alignment.bottomCenter,
        child: AppButton(
          key: const ValueKey('learn-here'),
          kind: ButtonKind.primary,
          icon: Icons.flag_rounded,
          label: l.learnHere,
          fontSize: 26,
          onTap: () async {
            await ref.read(profilesProvider.notifier).save(p.copyWith(region: _region));
            if (context.mounted) context.go('/');
          },
        ),
      ),
    );
  }
}
