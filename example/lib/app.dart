import 'package:flutter/material.dart';

import 'core/theme/example_theme.dart';
import 'features/auth/presentation/auth_gate.dart';

/// Root widget for the educational HosteDay example.
///
/// The app demonstrates authentication, profile management, custom API tables,
/// and realtime events in separated feature folders.
class HosteDayExampleApp extends StatelessWidget {
  const HosteDayExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HosteDay Example',
      debugShowCheckedModeBanner: false,
      darkTheme: ExampleTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const AuthGate(),
    );
  }
}
