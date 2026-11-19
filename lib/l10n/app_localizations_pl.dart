// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'EuLearn';

  @override
  String get chooseLanguage => 'Wybierz język';

  @override
  String get next => 'Dalej';

  @override
  String get yourName => 'Twoje imię';

  @override
  String get defaultName => 'Odkrywca';

  @override
  String get whereDoYouLive => 'Gdzie mieszkasz? Dotknij swojego kraju.';

  @override
  String thisIsMyCountry(String name) {
    return '$name to mój kraj';
  }

  @override
  String get dailyJourney => 'Wyprawa dnia';

  @override
  String get explorer => 'Odkrywca';

  @override
  String get games => 'Gry';

  @override
  String get passport => 'Paszport';

  @override
  String get parents => 'Rodzice';

  @override
  String get modeFind => 'Gdzie to jest?';

  @override
  String get modeFlags => 'Czyja to flaga?';

  @override
  String get modeCapitals => 'Stolice';

  @override
  String get modeNeighbors => 'Sąsiedzi';

  @override
  String get modePuzzle => 'Układanka granic';

  @override
  String get modeListen => 'Posłuchaj po angielsku';

  @override
  String promptFind(String name) {
    return 'Pokaż $name';
  }

  @override
  String promptCapitalOf(String name) {
    return 'Stolica $name to…';
  }

  @override
  String get promptWhoseFlag => 'Czyja to flaga?';

  @override
  String promptPickFlag(String name) {
    return 'Wybierz flagę $name';
  }

  @override
  String promptWhereCapital(String capital) {
    return 'W którym kraju jest $capital?';
  }

  @override
  String promptNeighbors(String name) {
    return 'Z kim graniczy $name?';
  }

  @override
  String get promptPuzzle => 'Ułóż kraje na mapie';

  @override
  String get promptListen => 'Posłuchaj…';

  @override
  String thisIs(String name) {
    return 'To $name';
  }

  @override
  String capitalIs(String capital) {
    return 'Stolica: $capital';
  }

  @override
  String get legend => 'LEGENDA';

  @override
  String get legendHome => 'mój kraj';

  @override
  String get legendKnown => 'znam';

  @override
  String get legendLearning => 'uczę się';

  @override
  String get legendNew => 'nowy';

  @override
  String get legendUnseen => 'jeszcze nie';

  @override
  String get wellDone => 'Brawo!';

  @override
  String get again => 'Jeszcze raz';

  @override
  String get goHome => 'Do domu';

  @override
  String foundOf(int found, int total) {
    return '$found z $total';
  }

  @override
  String get skillLocation => 'miejsce';

  @override
  String get skillShape => 'kształt';

  @override
  String get skillFlag => 'flaga';

  @override
  String get skillCapital => 'stolica';

  @override
  String parentGate(int a, int b) {
    return 'Dla rodziców: ile to $a × $b?';
  }

  @override
  String get readAloud => 'Czytaj wszystko na głos';

  @override
  String get secondLanguage => 'Mów nazwy także po angielsku';

  @override
  String get language => 'Język';

  @override
  String get resetProgress => 'Wyzeruj postępy';

  @override
  String get resetConfirm => 'Usunąć wszystko, czego to dziecko się nauczyło?';

  @override
  String get deleteProfile => 'Usuń to dziecko';

  @override
  String get cancel => 'Anuluj';

  @override
  String countriesKnown(int n, int total) {
    return 'Znane kraje: $n z $total';
  }

  @override
  String get addChild => 'Dodaj dziecko';

  @override
  String get europe => 'EUROPA';

  @override
  String get meetFirst => 'Najpierw poznaj kilka krajów';

  @override
  String get back => 'Wróć';

  @override
  String get sayAgain => 'Powtórz';

  @override
  String get zoomIn => 'Przybliż';

  @override
  String get zoomOut => 'Oddal';

  @override
  String dayStreak(int n) {
    return '$n. dzień wyprawy';
  }

  @override
  String noVoice(String language) {
    return 'Na tym urządzeniu nie ma głosu dla języka: $language. Dodaj go w systemowych ustawieniach syntezy mowy.';
  }

  @override
  String get licenses => 'Licencje';
}
