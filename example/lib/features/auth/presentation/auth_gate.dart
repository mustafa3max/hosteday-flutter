import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../../home/presentation/home_shell.dart';
import 'pages/sign_in_page.dart';

/// Chooses the first screen according to the authentication state.
///
/// Similar to Firebase's auth gate pattern: unauthenticated users see the sign-in
/// page, while authenticated users enter the main app shell.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HosteDayUser?>(
      stream: HosteDay.auth.authStateChanges(),
      initialData: HosteDay.auth.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (user == null) {
          return const SignInPage();
        }

        return HomeShell(user: user);
      },
    );
  }
}
