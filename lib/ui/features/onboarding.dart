import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../core/map/geo_map.dart';
import '../core/map_screen.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

/// Language chosen during onboarding, before a profile exists.
class PendingLang extends Notifier<Lang?> {
  @override
  Lang? build() => null;
  void set(Lang? l) => state = l;
}

final pendingLangProvider = NotifierProvider<PendingLang, Lang?>(PendingLang.new);

/// First run (and "add a child"): language → name → my country.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends ConsumerState<OnboardingScreen> {
  final _map = GeoMapController();
  final _name = TextEditingController();
  int _step = 0;
  String? _home;

  @override
  void dispose() {
    _map.dispose();
    _name.dispose();
    super.dispose();
  }

  Lang get _lang => ref.read(pendingLangProvider) ?? Lang.en;

  void _pickLang(Lang l) {
    ref.read(pendingLangProvider.notifier).set(l);
    setState(() => _step = 1);
  }

  void _toMap() {
    FocusScope.of(context).unfocus();
    // Suggest the country the device is set to, if it is on the map.
    final region = PlatformDispatcher.instance.locale.countryCode?.toLowerCase();
    setState(() {
      _step = 2;
      _home = region != null && ref.read(geoProvider).playable(region) ? region : null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      ref.read(speechProvider).say([(l.whereDoYouLive, _lang)]);
      if (_home != null) _map.focusOn([_home!]);
    });
  }

  void _pickHome(String code) {
    setState(() => _home = code);
    _map.focusOn([code]);
    ref.read(speechProvider).say([(ref.read(geoProvider).text(code, _lang).name, _lang)]);
  }

  Future<void> _finish() async {
    final l = AppLocalizations.of(context)!;
    final name = _name.text.trim();
    await ref.read(profilesProvider.notifier).create(name: name.isEmpty ? l.defaultName : name, home: _home!, lang: _lang);
    ref.read(pendingLangProvider.notifier).set(null);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final geo = ref.watch(geoProvider);
    final canLeave = ref.watch(profilesProvider).active != null;

    if (_step == 2) {
      return MapScreen(
        controller: _map,
        showBack: canLeave,
        showLegend: false,
        styleOf: (c) => CountryStyle(stage: c == _home ? Stage.known : Stage.unseen, home: c == _home, ribbon: c == _home ? 1 : 0),
        labelOf: (c) => geo.text(c, _lang).name,
        onTap: _pickHome,
        top: PromptBar(
          text: l.whereDoYouLive,
          onSpeak: () => ref.read(speechProvider).say([(l.whereDoYouLive, _lang)]),
        ),
        center: _home == null
            ? null
            : Align(
                alignment: Alignment.bottomCenter,
                child: AppButton(
                  key: const ValueKey('confirm-home'),
                  kind: ButtonKind.primary,
                  icon: Icons.home_rounded,
                  label: l.thisIsMyCountry(geo.text(_home!, _lang).name),
                  fontSize: 26,
                  onTap: _finish,
                ),
              ),
      );
    }

    return MapScreen(
      styleOf: (c) => const CountryStyle(stage: Stage.unseen, dim: true),
      showBack: canLeave,
      showLegend: false,
      interactive: false,
      center: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: AppPanel(
            padding: const EdgeInsets.all(20),
            child: _step == 0
                ? Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    // Shown in both languages: nobody has chosen one yet.
                    Text('Wybierz język · Choose your language', textAlign: TextAlign.center, style: Tok.display(24)),
                    const SizedBox(height: 16),
                    AppButton(key: const ValueKey('lang-pl'), label: 'Polski', fontSize: 30, onTap: () => _pickLang(Lang.pl)),
                    const SizedBox(height: 12),
                    AppButton(key: const ValueKey('lang-en'), label: 'English', fontSize: 30, onTap: () => _pickLang(Lang.en)),
                  ])
                : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(l.yourName, style: Tok.display(28)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _name,
                      maxLength: 16,
                      textCapitalization: TextCapitalization.words,
                      style: Tok.text(24, bold: true),
                      decoration: InputDecoration(
                        hintText: l.defaultName,
                        counterText: '',
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Tok.ink, width: Tok.stroke)),
                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Tok.signal, width: Tok.stroke)),
                      ),
                      onSubmitted: (_) => _toMap(),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      key: const ValueKey('name-next'),
                      kind: ButtonKind.primary,
                      label: l.next,
                      icon: Icons.arrow_forward_rounded,
                      onTap: _toMap,
                    ),
                  ]),
          ),
        ),
      ),
    );
  }
}
