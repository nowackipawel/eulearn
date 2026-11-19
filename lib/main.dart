import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/geo_repository.dart';
import 'data/speech_service.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(['Natural Earth'], 'Map data: Natural Earth. Public domain. naturalearthdata.com');
    yield const LicenseEntryWithLineBreaks(['flag-icons'], 'Flags: flag-icons by Panayiotis Lipiridis. MIT License.');
    yield LicenseEntryWithLineBreaks(['Andika'], await rootBundle.loadString('assets/fonts/OFL-Andika.txt'));
    yield LicenseEntryWithLineBreaks(['Sofia Sans'], await rootBundle.loadString('assets/fonts/OFL-SofiaSans.txt'));
  });
  final geo = await GeoRepository.load(rootBundle);
  final prefs = await SharedPreferences.getInstance();
  final speech = SpeechService();
  await speech.init();
  runApp(ProviderScope(
    overrides: [
      geoProvider.overrideWithValue(geo),
      prefsProvider.overrideWithValue(prefs),
      speechProvider.overrideWithValue(speech),
    ],
    child: const App(),
  ));
}
