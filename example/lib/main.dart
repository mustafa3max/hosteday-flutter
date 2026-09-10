import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/bootstrap/hosteday_initializer.dart';

/// Application entry point.
///
/// This file intentionally stays small. All Hosteday configuration lives in
/// [HostedayInitializer], and the UI starts from [HostedayExampleApp].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HostedayInitializer.initialize();

  runApp(const HostedayExampleApp());
}
