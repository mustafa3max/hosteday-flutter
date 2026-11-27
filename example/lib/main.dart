import 'package:flutter/widgets.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

import 'app.dart';

/// Application entry point.
///
/// Hosteday loads its configuration exclusively from `assets/hosteday_config.json`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hosteday.initializeApp(
    authStorage: HostedaySharedPreferencesAuthStorage(),
  );

  runApp(const App());
}
