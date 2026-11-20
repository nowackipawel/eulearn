import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../domain/question_factory.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../core/map/geo_map.dart';
import '../core/map_screen.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

/// Free map: touch a country to meet it. No questions, no marks.
class ExplorerScreen extends ConsumerStatefulWidget {
  const ExplorerScreen({super.key});
  @override
  ConsumerState<ExplorerScreen> createState() => _ExplorerState();
}

class _ExplorerState extends ConsumerState<ExplorerScreen> {
  final _map = GeoMapController();
  String? _code;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  void _open(String code) {
    final p = ref.read(profilesProvider).active!;
    final geo = ref.read(geoProvider);
    setState(() => _code = code);
    // Meeting a country here counts the same as an intro card in a round.
    ref
        .read(profilesProvider.notifier)
        .save(p.copyWith(progress: record(p.progress, IntroCard(code), clean: true, now: DateTime.now())));
    WidgetsBinding.instance.addPostFrameCallback((_) => _map.focusOn([code]));
    ref.read(speechProvider).say([
      (geo.text(code, p.lang).name, p.lang),
      if (p.secondLang) (geo.text(code, p.lang.other).name, p.lang.other),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profilesProvider).active!;
    final geo = ref.watch(geoProvider);
    final l = AppLocalizations.of(context)!;
    final speech = ref.read(speechProvider);
    final code = _code;

    Widget speakers(String Function(Lang) text) => Row(mainAxisSize: MainAxisSize.min, children: [
          SpeakerButton(
              tag: p.lang.name.toUpperCase(), semanticLabel: l.sayAgain, onTap: () => speech.say([(text(p.lang), p.lang)])),
          if (p.secondLang) ...[
            const SizedBox(width: 8),
            SpeakerButton(
                tag: p.lang.other.name.toUpperCase(),
                semanticLabel: l.sayAgain,
                onTap: () => speech.say([(text(p.lang.other), p.lang.other)])),
          ],
        ]);

    Widget card(String c) {
      final t = geo.text(c, p.lang), o = geo.text(c, p.lang.other);
      final i = geo.tint[c]!;
      final home = c == p.home;
      final skills = [
        (Skill.location, Icons.place_rounded, l.skillLocation),
        (Skill.shape, Icons.extension_rounded, l.skillShape),
        (Skill.flag, Icons.flag_rounded, l.skillFlag),
        (Skill.capital, Icons.location_city_rounded, l.skillCapital),
      ];
      return AppPanel(
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              FlagImage(c, height: 66),
              const Spacer(),
              // The same ribbon as on the map, large enough to read.
              CountryThumb(
                shape: geo.views[p.region]!.shapes[c]!,
                tint: home ? Tok.homeTint : Tok.tints[i],
                ribbonColor: home ? Tok.homeRibbon : Tok.ribbons[i],
                ribbon: p.progress.skillsKnown(c) / 4,
                size: const Size(88, 66),
              ),
            ]),
            const SizedBox(height: 8),
            Text(t.name, style: Tok.display(30)),
            if (p.secondLang) Text(o.name, style: Tok.text(17, italic: true)),
            const SizedBox(height: 6),
            speakers((lang) => geo.text(c, lang).name),
            const SizedBox(height: 10),
            Text(l.capitalIs(t.capital), style: Tok.text(20, bold: true)),
            if (p.secondLang && o.capital != t.capital) Text(o.capital, style: Tok.text(17, italic: true)),
            const SizedBox(height: 6),
            speakers((lang) => geo.text(c, lang).capital),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final (skill, icon, label) in skills)
                _SkillMark(icon: icon, label: label, done: p.progress.of(c, skill).level >= 3),
            ]),
            if (t.hook != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(t.hook!, style: Tok.text(18))),
          ]),
        ),
      );
    }

    return MapScreen(
      controller: _map,
      styleOf: (c) => progressStyle(p, c, dim: code != null && c != code),
      labelOf: (c) => geo.text(c, p.lang).name,
      pins: {?code},
      onTap: _open,
      right: code == null ? null : card(code),
    );
  }
}

/// One quarter of a country's ribbon: a learned skill is filled in.
class _SkillMark extends StatelessWidget {
  const _SkillMark({required this.icon, required this.label, required this.done});
  final IconData icon;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        checked: done,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: done ? Tok.ink : Tok.paper,
            border: Border.all(color: Tok.ink, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(done ? Icons.check_rounded : icon, size: 20, color: done ? Tok.paper : Tok.ink),
            const SizedBox(width: 4),
            ExcludeSemantics(child: Text(label, style: Tok.text(15, color: done ? Tok.paper : Tok.ink))),
          ]),
        ),
      );
}
