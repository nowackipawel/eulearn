import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models.dart';
import '../../domain/question_factory.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

/// The whole continent on one sheet: every country with its ribbon, a stamp
/// once the ribbon is closed.
class PassportScreen extends ConsumerWidget {
  const PassportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profilesProvider).active!;
    final geo = ref.watch(geoProvider);
    final l = AppLocalizations.of(context)!;
    final order = learningOrder(geo.graph, p.home);
    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(Tok.gap),
        child: Column(children: [
          Row(children: [
            AppButton(icon: Icons.arrow_back_rounded, semanticLabel: l.back, onTap: () => context.pop()),
            const SizedBox(width: Tok.gap),
            Text(l.europe, style: Tok.mapLabel(30)),
            const Spacer(),
            AppPanel(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text('${p.progress.knownCount} / ${order.length}', style: Tok.display(26)),
            ),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 132,
                mainAxisExtent: 128,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: order.length,
              itemBuilder: (context, n) {
                final c = order[n];
                final t = geo.text(c, p.lang), o = geo.text(c, p.lang.other);
                final i = geo.tint[c]!;
                final home = c == p.home;
                final stage = home && p.progress.stage(c) == Stage.unseen ? Stage.fresh : p.progress.stage(c);
                return Semantics(
                  button: true,
                  label: t.name,
                  child: GestureDetector(
                    onTap: () => ref.read(speechProvider).say([(t.name, p.lang), if (p.secondLang) (o.name, p.lang.other)]),
                    child: AppPanel(
                      padding: const EdgeInsets.all(6),
                      child: Stack(children: [
                        Column(children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (_, box) => CountryThumb(
                                shape: geo.europe.shapes[c]!,
                                tint: home ? Tok.homeTint : Tok.tints[i],
                                ribbonColor: home ? Tok.homeRibbon : Tok.ribbons[i],
                                stage: stage,
                                ribbon: p.progress.skillsKnown(c) / 4,
                                size: box.biggest,
                              ),
                            ),
                          ),
                          FittedBox(child: Text(t.name, maxLines: 1, style: Tok.display(15))),
                          if (p.secondLang) FittedBox(child: Text(o.name, maxLines: 1, style: Tok.text(11, italic: true))),
                        ]),
                        if (stage == Stage.known)
                          const Align(
                            alignment: Alignment.topRight,
                            child: Icon(Icons.verified_rounded, color: Tok.signal, size: 26),
                          ),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
