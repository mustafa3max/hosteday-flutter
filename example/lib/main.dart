import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/bootstrap/hosteday_initializer.dart';

/// Application entry point.
///
/// This file intentionally stays small. All HosteDay configuration lives in
/// [HosteDayInitializer], and the UI starts from [HosteDayExampleApp].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HosteDayInitializer.initialize();

  runApp(const HosteDayExampleApp());
}
