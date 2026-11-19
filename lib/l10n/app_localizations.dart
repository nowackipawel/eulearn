import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'EuLearn'**
  String get appTitle;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @defaultName.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get defaultName;

  /// No description provided for @whereDoYouLive.
  ///
  /// In en, this message translates to:
  /// **'Where do you live? Tap your country.'**
  String get whereDoYouLive;

  /// No description provided for @thisIsMyCountry.
  ///
  /// In en, this message translates to:
  /// **'{name} is my country'**
  String thisIsMyCountry(String name);

  /// No description provided for @dailyJourney.
  ///
  /// In en, this message translates to:
  /// **'Daily journey'**
  String get dailyJourney;

  /// No description provided for @explorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get explorer;

  /// No description provided for @games.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get games;

  /// No description provided for @passport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get passport;

  /// No description provided for @parents.
  ///
  /// In en, this message translates to:
  /// **'Parents'**
  String get parents;

  /// No description provided for @modeFind.
  ///
  /// In en, this message translates to:
  /// **'Where is it?'**
  String get modeFind;

  /// No description provided for @modeFlags.
  ///
  /// In en, this message translates to:
  /// **'Whose flag?'**
  String get modeFlags;

  /// No description provided for @modeCapitals.
  ///
  /// In en, this message translates to:
  /// **'Capitals'**
  String get modeCapitals;

  /// No description provided for @modeNeighbors.
  ///
  /// In en, this message translates to:
  /// **'Neighbours'**
  String get modeNeighbors;

  /// No description provided for @modePuzzle.
  ///
  /// In en, this message translates to:
  /// **'Border puzzle'**
  String get modePuzzle;

  /// No description provided for @modeListen.
  ///
  /// In en, this message translates to:
  /// **'Listen in Polish'**
  String get modeListen;

  /// No description provided for @promptFind.
  ///
  /// In en, this message translates to:
  /// **'Find {name}'**
  String promptFind(String name);

  /// No description provided for @promptCapitalOf.
  ///
  /// In en, this message translates to:
  /// **'The capital of {name} is…'**
  String promptCapitalOf(String name);

  /// No description provided for @promptWhoseFlag.
  ///
  /// In en, this message translates to:
  /// **'Whose flag is this?'**
  String get promptWhoseFlag;

  /// No description provided for @promptPickFlag.
  ///
  /// In en, this message translates to:
  /// **'Pick the flag of {name}'**
  String promptPickFlag(String name);

  /// No description provided for @promptWhereCapital.
  ///
  /// In en, this message translates to:
  /// **'Which country is {capital} in?'**
  String promptWhereCapital(String capital);

  /// No description provided for @promptNeighbors.
  ///
  /// In en, this message translates to:
  /// **'Which countries border {name}?'**
  String promptNeighbors(String name);

  /// No description provided for @promptPuzzle.
  ///
  /// In en, this message translates to:
  /// **'Put the countries on the map'**
  String get promptPuzzle;

  /// No description provided for @promptListen.
  ///
  /// In en, this message translates to:
  /// **'Listen…'**
  String get promptListen;

  /// No description provided for @thisIs.
  ///
  /// In en, this message translates to:
  /// **'This is {name}'**
  String thisIs(String name);

  /// No description provided for @capitalIs.
  ///
  /// In en, this message translates to:
  /// **'Capital: {capital}'**
  String capitalIs(String capital);

  /// No description provided for @legend.
  ///
  /// In en, this message translates to:
  /// **'LEGEND'**
  String get legend;

  /// No description provided for @legendHome.
  ///
  /// In en, this message translates to:
  /// **'my country'**
  String get legendHome;

  /// No description provided for @legendKnown.
  ///
  /// In en, this message translates to:
  /// **'I know it'**
  String get legendKnown;

  /// No description provided for @legendLearning.
  ///
  /// In en, this message translates to:
  /// **'learning'**
  String get legendLearning;

  /// No description provided for @legendNew.
  ///
  /// In en, this message translates to:
  /// **'new'**
  String get legendNew;

  /// No description provided for @legendUnseen.
  ///
  /// In en, this message translates to:
  /// **'not yet'**
  String get legendUnseen;

  /// No description provided for @wellDone.
  ///
  /// In en, this message translates to:
  /// **'Well done!'**
  String get wellDone;

  /// No description provided for @again.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get again;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get goHome;

  /// No description provided for @foundOf.
  ///
  /// In en, this message translates to:
  /// **'{found} of {total}'**
  String foundOf(int found, int total);

  /// No description provided for @skillLocation.
  ///
  /// In en, this message translates to:
  /// **'place'**
  String get skillLocation;

  /// No description provided for @skillShape.
  ///
  /// In en, this message translates to:
  /// **'shape'**
  String get skillShape;

  /// No description provided for @skillFlag.
  ///
  /// In en, this message translates to:
  /// **'flag'**
  String get skillFlag;

  /// No description provided for @skillCapital.
  ///
  /// In en, this message translates to:
  /// **'capital'**
  String get skillCapital;

  /// No description provided for @parentGate.
  ///
  /// In en, this message translates to:
  /// **'For parents: what is {a} × {b}?'**
  String parentGate(int a, int b);

  /// No description provided for @readAloud.
  ///
  /// In en, this message translates to:
  /// **'Read everything aloud'**
  String get readAloud;

  /// No description provided for @secondLanguage.
  ///
  /// In en, this message translates to:
  /// **'Say names in Polish too'**
  String get secondLanguage;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @resetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset progress'**
  String get resetProgress;

  /// No description provided for @resetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Erase everything this child has learned?'**
  String get resetConfirm;

  /// No description provided for @deleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Delete this child'**
  String get deleteProfile;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @countriesKnown.
  ///
  /// In en, this message translates to:
  /// **'Countries known: {n} of {total}'**
  String countriesKnown(int n, int total);

  /// No description provided for @addChild.
  ///
  /// In en, this message translates to:
  /// **'Add a child'**
  String get addChild;

  /// No description provided for @europe.
  ///
  /// In en, this message translates to:
  /// **'EUROPE'**
  String get europe;

  /// No description provided for @meetFirst.
  ///
  /// In en, this message translates to:
  /// **'Meet a few countries first'**
  String get meetFirst;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @sayAgain.
  ///
  /// In en, this message translates to:
  /// **'Say it again'**
  String get sayAgain;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'Day {n} of the journey'**
  String dayStreak(int n);

  /// No description provided for @noVoice.
  ///
  /// In en, this message translates to:
  /// **'No voice for {language} is installed on this device. Add one in the system text-to-speech settings.'**
  String noVoice(String language);

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licences'**
  String get licenses;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
