// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'EuLearn';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get next => 'Next';

  @override
  String get yourName => 'Your name';

  @override
  String get defaultName => 'Explorer';

  @override
  String get whereDoYouLive => 'Where do you live? Tap your country.';

  @override
  String thisIsMyCountry(String name) {
    return '$name is my country';
  }

  @override
  String get dailyJourney => 'Daily journey';

  @override
  String get explorer => 'Explorer';

  @override
  String get games => 'Games';

  @override
  String get passport => 'Passport';

  @override
  String get parents => 'Parents';

  @override
  String get modeFind => 'Where is it?';

  @override
  String get modeFlags => 'Whose flag?';

  @override
  String get modeCapitals => 'Capitals';

  @override
  String get modeNeighbors => 'Neighbours';

  @override
  String get modePuzzle => 'Border puzzle';

  @override
  String get modeListen => 'Listen in Polish';

  @override
  String promptFind(String name) {
    return 'Find $name';
  }

  @override
  String promptCapitalOf(String name) {
    return 'The capital of $name is…';
  }

  @override
  String get promptWhoseFlag => 'Whose flag is this?';

  @override
  String promptPickFlag(String name) {
    return 'Pick the flag of $name';
  }

  @override
  String promptWhereCapital(String capital) {
    return 'Which country is $capital in?';
  }

  @override
  String promptNeighbors(String name) {
    return 'Which countries border $name?';
  }

  @override
  String get promptPuzzle => 'Put the countries on the map';

  @override
  String get promptListen => 'Listen…';

  @override
  String thisIs(String name) {
    return 'This is $name';
  }

  @override
  String capitalIs(String capital) {
    return 'Capital: $capital';
  }

  @override
  String get legend => 'LEGEND';

  @override
  String get legendHome => 'my country';

  @override
  String get legendKnown => 'I know it';

  @override
  String get legendLearning => 'learning';

  @override
  String get legendNew => 'new';

  @override
  String get legendUnseen => 'not yet';

  @override
  String get wellDone => 'Well done!';

  @override
  String get again => 'Again';

  @override
  String get goHome => 'Home';

  @override
  String foundOf(int found, int total) {
    return '$found of $total';
  }

  @override
  String get skillLocation => 'place';

  @override
  String get skillShape => 'shape';

  @override
  String get skillFlag => 'flag';

  @override
  String get skillCapital => 'capital';

  @override
  String parentGate(int a, int b) {
    return 'For parents: what is $a × $b?';
  }

  @override
  String get readAloud => 'Read everything aloud';

  @override
  String get secondLanguage => 'Say names in Polish too';

  @override
  String get language => 'Language';

  @override
  String get resetProgress => 'Reset progress';

  @override
  String get resetConfirm => 'Erase everything this child has learned?';

  @override
  String get deleteProfile => 'Delete this child';

  @override
  String get cancel => 'Cancel';

  @override
  String countriesKnown(int n, int total) {
    return 'Countries known: $n of $total';
  }

  @override
  String get addChild => 'Add a child';

  @override
  String get meetFirst => 'Meet a few countries first';

  @override
  String get back => 'Back';

  @override
  String get sayAgain => 'Say it again';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String dayStreak(int n) {
    return 'Day $n of the journey';
  }

  @override
  String noVoice(String language) {
    return 'No voice for $language is installed on this device. Add one in the system text-to-speech settings.';
  }

  @override
  String get licenses => 'Licences';

  @override
  String get soundEffects => 'Sound effects';

  @override
  String get continentEurope => 'Europe';

  @override
  String get continentAsia => 'Asia';

  @override
  String get continentAfrica => 'Africa';

  @override
  String get continentNorthAmerica => 'North America';

  @override
  String get continentSouthAmerica => 'South America';

  @override
  String get continentOceania => 'Oceania';

  @override
  String get continents => 'Continents';

  @override
  String get learnHere => 'Learn here';

  @override
  String promptNeighborsPlural(String name) {
    return 'Which countries border $name?';
  }

  @override
  String get hint => 'Hint';

  @override
  String get skip => 'Skip';
}
