import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/geo_repository.dart';
import '../../data/profile.dart';
import '../../domain/models.dart';
import '../../domain/question_factory.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../core/map/geo_map.dart';
import '../core/map_screen.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

/// One round of any mode. Modes differ only in the question type; the loop,
/// feedback and progress recording are shared.
class RoundScreen extends ConsumerStatefulWidget {
  const RoundScreen({super.key, required this.mode, this.seed});
  final RoundMode mode;

  /// Fixed seed (tests, multiplayer); defaults to the clock.
  final int? seed;

  @override
  ConsumerState<RoundScreen> createState() => _RoundState();
}

class _RoundState extends ConsumerState<RoundScreen> with SingleTickerProviderStateMixin {
  final _map = GeoMapController();
  late final _ribbon = AnimationController(vsync: this, duration: Tok.draw)..addListener(() => setState(() {}));
  String? _ribbonCode;
  double _ribbonFrom = 0, _ribbonTo = 0;

  late GameSession _s;
  late List<String> _region;
  final _missed = <int>{};
  final _found = <String>{}; // neighbours found
  final _placed = <String>{}; // puzzle pieces placed
  final _ruledOut = <String>{}; // wrong options already tried
  String? _piece; // selected puzzle piece
  String? _note; // "This is Spain" after a wrong tap
  bool _good = false; // right-answer feedback is showing

  Profile get _p => ref.read(profilesProvider).active!;
  GeoRepository get _geo => ref.read(geoProvider);
  AppLocalizations get _l => AppLocalizations.of(context)!;
  GeoText _t(String code) => _geo.text(code, _p.lang);
  GeoText _o(String code) => _geo.text(code, _p.lang.other);
  Question get _q => _s.current;

  @visibleForTesting
  String get debugCurrentCode => _q.code;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _ribbon.dispose();
    _map.dispose();
    super.dispose();
  }

  void _start() {
    final now = DateTime.now();
    final qs = buildRound(
      mode: widget.mode,
      graph: _geo.graph,
      home: _p.home,
      progress: _p.progress,
      seed: widget.seed ?? now.millisecondsSinceEpoch,
      now: now,
      secondLang: _p.secondLang,
    );
    _s = GameSession(seed: widget.seed ?? 0, questions: qs, playerIds: [_p.id]);
    _region = activePool(learningOrder(_geo.graph, _p.home), _p.progress);
    _missed.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _enter());
  }

  /// Camera and narrator for the question that just became current.
  void _enter() {
    if (!mounted) return;
    _found.clear();
    _placed.clear();
    _ruledOut.clear();
    _piece = null;
    _note = null;
    _good = false;
    if (_s.finished) {
      ref.read(profilesProvider.notifier).save(_p.played(DateTime.now()));
      _map.focusOn(_region);
      _say([(_l.wellDone, _p.lang)], always: true);
      setState(() {});
      return;
    }
    final q = _q;
    switch (q) {
      case IntroCard():
        // Meeting a country counts: it appears on the map straight away.
        _save(record(_p.progress, q, clean: true, now: DateTime.now()));
        _map.focusOn([q.code]);
      case ChoiceQuestion(kind: ChoiceKind.countryOfFlag) || TapOnMapQuestion():
        _map.focusOn({..._region, q.code});
      case ChoiceQuestion():
        _map.focusOn([q.code]);
      case NeighborsQuestion():
        _map.focusOn([q.code, ...q.answers]);
      case PlacePiecesQuestion():
        _map.focusOn({for (final c in q.pieces) ...[c, ..._geo.graph[c]!.around]});
    }
    _speakPrompt();
    setState(() {});
  }

  void _say(List<(String, Lang)> parts, {bool always = false}) {
    if (always || _p.readAloud) ref.read(speechProvider).say(parts);
  }

  /// A name in the child's language, then in the second one.
  List<(String, Lang)> _both(String ui, String other) =>
      [(ui, _p.lang), if (_p.secondLang) (other, _p.lang.other)];

  String get _prompt {
    final q = _q;
    if (q.otherLang) return _l.promptListen;
    return switch (q) {
      IntroCard() => _l.thisIs(_t(q.code).name),
      TapOnMapQuestion(byCapital: true) => _l.promptWhereCapital(_t(q.code).capital),
      TapOnMapQuestion() => _l.promptFind(_t(q.code).acc),
      ChoiceQuestion(kind: ChoiceKind.flagOfCountry) => _l.promptPickFlag(_t(q.code).gen),
      ChoiceQuestion(kind: ChoiceKind.countryOfFlag) => _l.promptWhoseFlag,
      ChoiceQuestion() => _l.promptCapitalOf(_t(q.code).gen),
      NeighborsQuestion() => _l.promptNeighbors(_t(q.code).name),
      PlacePiecesQuestion() => _l.promptPuzzle,
    };
  }

  void _speakPrompt({bool always = false}) {
    final q = _q;
    if (q.otherLang) {
      // Listening items are spoken in the second language by its own voice.
      _say([(_o(q.code).name, _p.lang.other)], always: true);
    } else if (q is IntroCard) {
      _say([(_prompt, _p.lang), (_l.capitalIs(_t(q.code).capital), _p.lang), if (_p.secondLang) (_o(q.code).name, _p.lang.other)],
          always: always);
    } else {
      _say([(_prompt, _p.lang)], always: always);
    }
  }

  void _save(Progress progress) => ref.read(profilesProvider.notifier).save(_p.copyWith(progress: progress));

  void _right() {
    final q = _q;
    final clean = _s.attempts == 0 && !_s.hinted;
    if (q is! IntroCard) {
      final before = _p.progress.skillsKnown(q.code) / 4;
      final next = record(_p.progress, q, clean: clean, now: DateTime.now());
      _save(next);
      // The signature moment: the border ribbon draws itself further.
      _ribbonCode = q.code;
      _ribbonFrom = before;
      _ribbonTo = next.skillsKnown(q.code) / 4;
      if (_ribbonTo != _ribbonFrom) _ribbon.forward(from: 0);
      final capital = q.skill == Skill.capital;
      _say(_both(capital ? _t(q.code).capital : _t(q.code).name, capital ? _o(q.code).capital : _o(q.code).name),
          always: true);
    }
    setState(() {
      _good = q is! IntroCard;
      _note = null;
    });
    Future<void>.delayed(Duration(milliseconds: q is IntroCard ? 0 : 1300), () {
      if (!mounted) return;
      _s = _s.apply(Answer(playerId: _p.id, correct: true));
      _enter();
    });
  }

  void _wrong(String? tapped) {
    if (_q.scored) _missed.add(_scoredIndex);
    _s = _s.apply(Answer(playerId: _p.id, correct: false));
    if (tapped != null) {
      _ruledOut.add(tapped);
      _note = _l.thisIs(_t(tapped).name);
      _say([(_note!, _p.lang)], always: true);
    }
    final q = _q;
    if (_s.hintDue) {
      // Second miss: narrow it down.
      if (q is TapOnMapQuestion) _map.focusOn([q.code, ..._geo.graph[q.code]!.around]);
      if (q.otherLang) _say([(_t(q.code).name, _p.lang)], always: true);
    }
    setState(() {});
  }

  int get _scoredIndex => _s.questions.take(_s.index).where((q) => q.scored).length;

  void _tapMap(String code) {
    if (_good || _s.finished) return;
    final q = _q;
    switch (q) {
      case TapOnMapQuestion():
        code == q.code ? _right() : _wrong(code);
      case NeighborsQuestion():
        if (code == q.code || _found.contains(code)) return;
        if (!q.answers.contains(code)) return _wrong(code);
        setState(() => _found.add(code));
        if (_found.length == q.answers.length) {
          _right();
        } else {
          _say(_both(_t(code).name, _o(code).name), always: true);
        }
      case PlacePiecesQuestion():
        if (_piece != null) _place(_piece!, code);
      case IntroCard() || ChoiceQuestion():
        break;
    }
  }

  void _place(String piece, String? target) {
    final q = _q as PlacePiecesQuestion;
    if (_good || _placed.contains(piece)) return;
    if (target != piece) return _wrong(null);
    setState(() {
      _placed.add(piece);
      _piece = null;
    });
    if (_placed.length == q.pieces.length) {
      _right();
    } else {
      _say(_both(_t(piece).name, _o(piece).name), always: true);
    }
  }

  CountryStyle _style(String code) {
    final p = ref.read(profilesProvider).active!;
    final q = _s.finished ? null : _q;
    final focusOne = q is IntroCard || (q is ChoiceQuestion && q.kind != ChoiceKind.countryOfFlag);
    var st = progressStyle(
      p,
      code,
      dim: focusOne && code != q!.code,
      hidden: q is PlacePiecesQuestion && q.pieces.contains(code) && !_placed.contains(code),
    );
    if (code == _ribbonCode && _ribbon.isAnimating) {
      final t = Curves.easeOutCubic.transform(_ribbon.value);
      st = CountryStyle(stage: st.stage, ribbon: _ribbonFrom + (_ribbonTo - _ribbonFrom) * t, home: st.home, dim: st.dim);
    }
    return st;
  }

  String? _label(String code) {
    if (_s.finished) return _t(code).name;
    final q = _q;
    return switch (q) {
      IntroCard() => code == q.code ? _t(code).name : null,
      ChoiceQuestion(kind: ChoiceKind.capitalOfCountry) => code == q.code ? _t(code).name : null,
      ChoiceQuestion(kind: ChoiceKind.flagOfCountry) => code == q.code && !q.otherLang ? _t(code).name : null,
      NeighborsQuestion() => code == q.code || _found.contains(code) ? _t(code).name : null,
      _ => _good && code == q.code ? _t(code).name : null,
    };
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(profilesProvider); // repaint the map when progress changes
    final l = _l;
    if (_s.questions.isEmpty) {
      return MapScreen(
        styleOf: (c) => progressStyle(_p, c),
        interactive: false,
        center: AppPanel(child: Text(l.meetFirst, style: Tok.display(28))),
      );
    }
    if (_s.finished) return _result(l);

    final q = _q;
    final blink = <String>{
      if (_s.hintDue && q is TapOnMapQuestion) q.code,
      if (_s.hintDue && q is NeighborsQuestion) ...q.answers.where((c) => !_found.contains(c)),
    };
    final map = MapScreen(
      controller: _map,
      styleOf: _style,
      labelOf: _label,
      blink: blink,
      pins: {if (q is IntroCard || q.skill == Skill.capital && q is ChoiceQuestion) q.code},
      onTap: _tapMap,
      mood: _good ? MascotMood.happy : MascotMood.idle,
      legendExtra: ProgressStrip(total: _s.scoredCount, done: _scoredIndex + (_good ? 1 : 0), missed: _missed),
      top: Column(mainAxisSize: MainAxisSize.min, children: [
        PromptBar(
          text: _good ? (q.skill == Skill.capital ? _t(q.code).capital : _t(q.code).name) : _prompt,
          good: _good,
          onSpeak: () => _speakPrompt(always: true),
          trailing: q is NeighborsQuestion
              ? Text(l.foundOf(_found.length, q.answers.length), style: Tok.display(24, color: Tok.voice))
              : null,
        ),
        if (_note != null && !_good)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AppPanel(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.info_outline_rounded, color: Tok.miss, size: 26),
                const SizedBox(width: 8),
                Text(_note!, style: Tok.text(18, bold: true)),
              ]),
            ),
          ),
      ]),
      right: switch (q) {
        IntroCard() => _introPanel(q, l),
        ChoiceQuestion() => _choicePanel(q),
        PlacePiecesQuestion() => _piecesPanel(q),
        _ => null,
      },
    );
    if (q is! PlacePiecesQuestion) return map;
    // Dropping a piece anywhere on the screen lands it on the map below.
    return DragTarget<String>(
      onAcceptWithDetails: (d) => _place(d.data, _map.codeAt(d.offset)),
      builder: (_, _, _) => map,
    );
  }

  Widget _introPanel(IntroCard q, AppLocalizations l) {
    final t = _t(q.code), o = _o(q.code);
    return AppPanel(
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FlagImage(q.code, height: 84),
          const SizedBox(height: 10),
          Text(t.name, style: Tok.display(32)),
          if (_p.secondLang) Text(o.name, style: Tok.text(18, italic: true)),
          const SizedBox(height: 6),
          Text(l.capitalIs(t.capital), style: Tok.text(20, bold: true)),
          if (t.hook != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(t.hook!, style: Tok.text(18))),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: AppButton(kind: ButtonKind.primary, label: l.next, icon: Icons.arrow_forward_rounded, onTap: _right),
          ),
        ]),
      ),
    );
  }

  Widget _choicePanel(ChoiceQuestion q) {
    void pick(String c) {
      if (_good) return;
      c == q.code ? _right() : _wrong(c);
    }

    final flags = q.kind == ChoiceKind.flagOfCountry;
    return AppPanel(
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (q.kind == ChoiceKind.countryOfFlag) ...[
            Center(child: FlagImage(q.code, height: 96)),
            const SizedBox(height: 12),
          ],
          if (flags)
            Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 12, children: [
              for (final c in q.options)
                AppButton(
                  key: ValueKey('opt-$c'),
                  semanticLabel: _t(c).name,
                  onTap: _ruledOut.contains(c) ? null : () => pick(c),
                  child: Padding(padding: const EdgeInsets.all(4), child: FlagImage(c, height: 66)),
                ),
            ])
          else
            for (final c in q.options)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  // Non-readers hear each answer before choosing.
                  SpeakerButton(
                    semanticLabel: _l.sayAgain,
                    onTap: () => _say([(q.kind == ChoiceKind.capitalOfCountry ? _t(c).capital : _t(c).name, _p.lang)],
                        always: true),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      key: ValueKey('opt-$c'),
                      label: q.kind == ChoiceKind.capitalOfCountry ? _t(c).capital : _t(c).name,
                      fontSize: 22,
                      onTap: _ruledOut.contains(c) ? null : () => pick(c),
                    ),
                  ),
                ]),
              ),
        ]),
      ),
    );
  }

  Widget _piecesPanel(PlacePiecesQuestion q) {
    Widget thumb(String c, Size size) {
      final i = _geo.tint[c]!;
      final home = c == _p.home;
      return CountryThumb(
        shape: _geo.europe.shapes[c]!,
        tint: home ? Tok.homeTint : Tok.tints[i],
        ribbonColor: home ? Tok.homeRibbon : Tok.ribbons[i],
        size: size,
      );
    }

    return AppPanel(
      child: SingleChildScrollView(
        child: Column(children: [
          for (final c in q.pieces.where((c) => !_placed.contains(c)))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Draggable<String>(
                data: c,
                dragAnchorStrategy: pointerDragAnchorStrategy,
                // Lifted above the finger so the piece is never hidden by it.
                feedback: Transform.translate(offset: const Offset(-60, -110), child: thumb(c, const Size(120, 96))),
                childWhenDragging: Opacity(opacity: 0.3, child: thumb(c, const Size(110, 80))),
                // Dragging is never the only way: tap a piece, then its place.
                child: AppButton(
                  key: ValueKey('piece-$c'),
                  kind: _piece == c ? ButtonKind.voice : ButtonKind.plain,
                  semanticLabel: _t(c).name,
                  onTap: () => setState(() => _piece = _piece == c ? null : c),
                  child: Padding(padding: const EdgeInsets.all(6), child: thumb(c, const Size(110, 80))),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _result(AppLocalizations l) {
    final stars = _s.stars(_p.id);
    return MapScreen(
      controller: _map,
      styleOf: (c) => progressStyle(_p, c),
      labelOf: (c) => _p.progress.seen(c) || c == _p.home ? _t(c).name : null,
      mood: MascotMood.happy,
      showBack: false,
      interactive: false,
      right: AppPanel(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(l.wellDone, style: Tok.display(40)),
          const SizedBox(height: 8),
          Semantics(
            label: '$stars / 3',
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < 3; i++)
                Icon(i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 56, color: i < stars ? Tok.signal : Tok.ink),
            ]),
          ),
          if (_p.streak > 1) Text(l.dayStreak(_p.streak), style: Tok.text(18, bold: true)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              kind: ButtonKind.primary,
              icon: Icons.replay_rounded,
              label: l.again,
              onTap: () => setState(_start),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: AppButton(icon: Icons.home_rounded, label: l.goHome, onTap: () => context.go('/')),
          ),
        ]),
      ),
    );
  }
}
