import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/profile.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

/// Behind a sums gate: progress, settings, profiles. Standard platform
/// controls here — this screen is for adults.
class ParentZoneScreen extends ConsumerStatefulWidget {
  const ParentZoneScreen({super.key});
  @override
  ConsumerState<ParentZoneScreen> createState() => _ParentZoneState();
}

class _ParentZoneState extends ConsumerState<ParentZoneScreen> {
  final _rng = Random();
  late final _a = 3 + _rng.nextInt(7), _b = 3 + _rng.nextInt(7);
  final _answer = TextEditingController();
  bool _open = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(profilesProvider);
    final p = state.active;
    final geo = ref.watch(geoProvider);
    final speech = ref.watch(speechProvider);
    final notifier = ref.read(profilesProvider.notifier);

    Widget body;
    if (!_open) {
      body = Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AppPanel(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(l.parentGate(_a, _b), style: Tok.text(22, bold: true)),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('gate'),
                  controller: _answer,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  style: Tok.text(26, bold: true),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  onChanged: (v) {
                    if (int.tryParse(v.trim()) == _a * _b) setState(() => _open = true);
                  },
                ),
              ]),
            ),
          ),
        ),
      );
    } else if (p == null) {
      body = const SizedBox.shrink();
    } else {
      final missing = Lang.values.where((x) => !speech.available.contains(x)).toList();
      body = ListView(children: [
        AppPanel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: Tok.display(28)),
            Text(l.countriesKnown(p.progress.knownCount, geo.graph.length), style: Tok.text(18)),
            if (p.streak > 0) Text(l.dayStreak(p.streak), style: Tok.text(18)),
          ]),
        ),
        const SizedBox(height: 12),
        AppPanel(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: [
            ListTile(
              title: Text(l.language, style: Tok.text(18)),
              trailing: SegmentedButton<Lang>(
                segments: const [
                  ButtonSegment(value: Lang.pl, label: Text('Polski')),
                  ButtonSegment(value: Lang.en, label: Text('English')),
                ],
                selected: {p.lang},
                onSelectionChanged: (s) => notifier.save(p.copyWith(lang: s.first)),
              ),
            ),
            SwitchListTile(
              title: Text(l.readAloud, style: Tok.text(18)),
              value: p.readAloud,
              onChanged: (v) => notifier.save(p.copyWith(readAloud: v)),
            ),
            SwitchListTile(
              title: Text(l.soundEffects, style: Tok.text(18)),
              value: p.sfx,
              onChanged: (v) => notifier.save(p.copyWith(sfx: v)),
            ),
            SwitchListTile(
              title: Text(l.secondLanguage, style: Tok.text(18)),
              value: p.secondLang,
              onChanged: (v) => notifier.save(p.copyWith(secondLang: v)),
            ),
            for (final m in missing)
              ListTile(
                leading: const Icon(Icons.info_outline_rounded, color: Tok.miss),
                title: Text(l.noVoice(m == Lang.pl ? 'Polski' : 'English'), style: Tok.text(15)),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final other in state.all.where((x) => x.id != p.id))
            AppButton(icon: Icons.person_rounded, label: other.name, onTap: () => notifier.select(other.id)),
          if (state.all.length < ProfileStore.maxProfiles)
            AppButton(icon: Icons.person_add_rounded, label: l.addChild, onTap: () => context.push('/onboarding')),
          AppButton(
            icon: Icons.restart_alt_rounded,
            label: l.resetProgress,
            onTap: () async {
              if (await _confirm(l.resetConfirm, l.resetProgress)) notifier.save(p.copyWith(progress: const Progress()));
            },
          ),
          AppButton(
            icon: Icons.delete_outline_rounded,
            label: l.deleteProfile,
            onTap: () async {
              if (await _confirm(l.resetConfirm, l.deleteProfile)) notifier.remove(p.id);
            },
          ),
          AppButton(
            icon: Icons.description_outlined,
            label: l.licenses,
            onTap: () => showLicensePage(context: context, applicationName: l.appTitle),
          ),
        ]),
      ]);
    }

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(Tok.gap),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppButton(icon: Icons.arrow_back_rounded, semanticLabel: l.back, onTap: () => context.pop()),
          const SizedBox(width: Tok.gap),
          Expanded(child: body),
        ]),
      ),
    );
  }

  /// Destructive actions are the one place a confirmation is right.
  Future<bool> _confirm(String question, String action) async {
    final l = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            content: Text(question, style: Tok.text(18)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
              TextButton(onPressed: () => Navigator.pop(c, true), child: Text(action)),
            ],
          ),
        ) ??
        false;
  }
}
