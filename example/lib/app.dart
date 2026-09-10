import 'package:flutter/material.dart';
import 'features/explorer/api_explorer_page.dart';

import 'core/theme/example_theme.dart';

/// Root widget for the educational Hosteday example.
class HostedayExampleApp extends StatelessWidget {
  const HostedayExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hosteday Example',
      debugShowCheckedModeBanner: false,
      darkTheme: ExampleTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const ApiExplorerPage(),
    );
  }
}
