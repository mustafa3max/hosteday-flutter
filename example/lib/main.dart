import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/bootstrap/hosteday_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HosteDayInitializer.initialize();
  runApp(const HosteDayExampleApp());
}
