import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/hosteday_auth_gate.dart';

class HosteDayExampleApp extends StatelessWidget {
  const HosteDayExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HosteDay Auth Example',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const HosteDayAuthGate(),
    );
  }
}
