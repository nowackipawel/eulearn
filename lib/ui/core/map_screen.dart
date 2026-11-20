import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/geo_repository.dart';
import '../../data/profile.dart';
import '../../domain/models.dart';
import '../../domain/question_factory.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import 'map/geo_map.dart';
import 'theme.dart';
import 'widgets.dart';

/// How a country looks given what the child knows about it.
CountryStyle progressStyle(Profile p, String code, {bool dim = false, bool hidden = false}) {
  final home = code == p.home;
  return CountryStyle(
    // My country is always shown in full colour: it is the fixed landmark.
    stage: home ? Stage.known : p.progress.stage(code),
    ribbon: p.progress.skillsKnown(code) / 4,
    home: home,
    dim: dim,
    hidden: hidden,
  );
}

/// Countries of the child's current continent, from home (or the continent's
/// anchor) outwards.
List<String> regionOrder(GeoRepository geo, Profile p) => learningOrder(
      geo.graph,
      p.home,
      region: geo.members(p.region),
      anchor: GeoRepository.anchors[p.region],
    );

String continentName(AppLocalizations l, String region) => switch (region) {
      'asia' => l.continentAsia,
      'africa' => l.continentAfrica,
      'north_america' => l.continentNorthAmerica,
      'south_america' => l.continentSouthAmerica,
      'oceania' => l.continentOceania,
      _ => l.continentEurope,
    };

/// The shell every map screen shares: full-bleed map, back top-left, prompt
/// top-centre, legend bottom-left, zoom bottom-right (docs/02 §9).
class MapScreen extends ConsumerWidget {
  const MapScreen({
    super.key,
    required this.styleOf,
    this.controller,
    this.labelOf,
    this.blink = const {},
    this.pins = const {},
    this.onTap,
    this.top,
    this.right,
    this.left,
    this.center,
    this.legendExtra,
    this.mood = MascotMood.idle,
    this.showBack = true,
    this.showLegend = true,
    this.interactive = true,
    this.mapKey,
    this.view,
    this.markers = true,
  });

  final CountryStyle Function(String code) styleOf;
  final GeoMapController? controller;
  final String? Function(String code)? labelOf;
  final Set<String> blink, pins;
  final ValueChanged<String>? onTap;
  final Widget? top, right, left, center, legendExtra;
  final MascotMood mood;
  final bool showBack, showLegend, interactive;
  final Key? mapKey;

  /// Map to show; defaults to the active profile's continent.
  final String? view;
  final bool markers;

  static double rightWidth(Size s) => math.min(360, s.width * 0.4);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final geo = ref.watch(geoProvider);
    final l = AppLocalizations.of(context)!;
    final mq = MediaQuery.of(context);
    final size = mq.size, safe = mq.padding;
    final roomy = size.height >= 600;
    final rightW = right == null ? 0.0 : rightWidth(size);
    final leftW = left == null ? 0.0 : math.min(340.0, size.width * 0.4);
    const g = Tok.gap;

    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: GeoMap(
            key: mapKey,
            view: geo.views[view ?? ref.watch(profilesProvider).active?.region ?? GeoRepository.world]!,
            geo: geo,
            styleOf: styleOf,
            labelOf: labelOf,
            blink: blink,
            pins: pins,
            onTap: onTap,
            controller: controller,
            interactive: interactive,
            markers: markers,
            padding: EdgeInsets.fromLTRB(
              safe.left + g + (left != null ? leftW + g : 0),
              safe.top + g + (top != null ? 76 : 0),
              safe.right + g + (right != null ? rightW + g : 0),
              safe.bottom + g,
            ),
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(g),
          child: Stack(children: [
            if (showBack)
              Align(
                alignment: Alignment.topLeft,
                child: AppButton(
                  icon: Icons.arrow_back_rounded,
                  semanticLabel: l.back,
                  onTap: () => context.canPop() ? context.pop() : context.go('/'),
                ),
              ),
            if (top != null)
              Positioned(
                top: 0,
                left: Tok.touch + g,
                right: right != null ? rightW + g : Tok.touch + g,
                child: Center(child: top),
              ),
            if (left != null) Positioned(top: 0, bottom: 0, left: 0, width: leftW, child: left!),
            if (right != null) Positioned(top: 0, bottom: 0, right: 0, width: rightW, child: right!),
            if (showLegend && left == null)
              Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Mascot(talking: ref.watch(speechProvider).talking, mood: mood, size: roomy ? 104 : 64),
                    const SizedBox(height: 6),
                    MapLegend(extra: legendExtra, roomy: roomy),
                  ],
                ),
              ),
            if (interactive && controller != null)
              Positioned(
                right: right != null ? rightW + g : 0,
                bottom: 0,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AppButton(icon: Icons.add_rounded, semanticLabel: l.zoomIn, onTap: () => controller!.zoomBy(1.6)),
                  const SizedBox(height: 10),
                  AppButton(icon: Icons.remove_rounded, semanticLabel: l.zoomOut, onTap: () => controller!.zoomBy(1 / 1.6)),
                ]),
              ),
            if (center != null) Center(child: center),
          ]),
        ),
      ]),
    );
  }
}

/// The map's legend: the single home for state keys and round progress.
/// Swatches speak their meaning when touched, for children who cannot read.
class MapLegend extends ConsumerWidget {
  const MapLegend({super.key, this.extra, required this.roomy});
  final Widget? extra;
  final bool roomy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final lang = Lang.values.byName(Localizations.localeOf(context).languageCode);
    final rows = [
      (const StageSwatch(Stage.known, home: true), l.legendHome),
      (const StageSwatch(Stage.known), l.legendKnown),
      (const StageSwatch(Stage.learning), l.legendLearning),
      (const StageSwatch(Stage.fresh), l.legendNew),
    ];
    Widget key(Widget swatch, String text) => Semantics(
          label: text,
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => ref.read(speechProvider).say([(text, lang)]),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                swatch,
                if (roomy) ...[const SizedBox(width: 10), Text(text, style: Tok.text(16))],
              ]),
            ),
          ),
        );
    return SizedBox(
      width: roomy ? 230 : 190,
      child: AppPanel(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (roomy) ...[
            Text(l.legend, style: Tok.mapLabel(13)),
            const Divider(color: Tok.ink, thickness: 2, height: 12),
            for (final (s, t) in rows) key(s, t),
          ] else
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [for (final (s, t) in rows) key(s, t)]),
          if (extra != null) ...[const SizedBox(height: 8), extra!],
        ]),
      ),
    );
  }
}

/// Ink bar with the spoken question and its "say again" button.
class PromptBar extends StatelessWidget {
  const PromptBar({super.key, required this.text, this.onSpeak, this.good = false, this.trailing});
  final String text;
  final VoidCallback? onSpeak;

  /// Turns green with a tick after a right answer.
  final bool good;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AnimatedContainer(
      duration: Tok.quick,
      padding: const EdgeInsets.fromLTRB(20, 4, 4, 4),
      decoration: BoxDecoration(
        color: good ? Tok.good : Tok.ink,
        borderRadius: BorderRadius.circular(Tok.radius),
        border: Border.all(color: Tok.ink, width: Tok.stroke),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (good) ...[const Icon(Icons.check_rounded, color: Tok.paper, size: 34), const SizedBox(width: 8)],
        Flexible(
          child: Semantics(
            liveRegion: true,
            child: Text(text, maxLines: 2, style: Tok.display(28, color: Tok.paper)),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 14), trailing!],
        const SizedBox(width: 14),
        if (onSpeak != null)
          SizedBox(height: 56, child: SpeakerButton(onTap: onSpeak!, semanticLabel: l.sayAgain))
        else
          const SizedBox(height: 56),
      ]),
    );
  }
}
