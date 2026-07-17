import 'package:flutter/material.dart';
import 'package:hosteday_flutter_example/features/posts/presentation/pages/home_page.dart';

import 'core/theme/example_theme.dart';

/// Root widget for the educational HosteDay example.
class HosteDayExampleApp extends StatelessWidget {
  const HosteDayExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HosteDay Example',
      debugShowCheckedModeBanner: false,
      darkTheme: ExampleTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const HomePage(),
    );
  }
}
