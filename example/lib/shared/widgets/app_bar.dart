import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';
import 'package:hosteday_flutter_example/features/auth/presentation/pages/sign_in_page.dart';

import '../../features/auth/presentation/auth_gate.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/posts/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

enum _AccountAction { login, register, profile, logout }

/// Shared application AppBar.
///
/// When unauthenticated, the account menu displays:
/// - Sign in
/// - Create account
///
/// When authenticated, it displays:
/// - Profile
/// - Sign out
class AppBarMy extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const AppBarMy({this.title = 'HosteDay Example', super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  Future<void> _openLogin(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SignInPage()));
  }

  Future<void> _openRegister(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const RegisterPage()));
  }

  Future<void> _openProfile(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProfilePage()));
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await HosteDay.client.auth.signOut();

      if (!context.mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign out failed: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleAccountAction(
    BuildContext context,
    _AccountAction action,
  ) async {
    switch (action) {
      case _AccountAction.login:
        await _openLogin(context);
        return;

      case _AccountAction.register:
        await _openRegister(context);
        return;

      case _AccountAction.profile:
        await _openProfile(context);
        return;

      case _AccountAction.logout:
        await _logout(context);
        return;
    }
  }

  List<PopupMenuEntry<_AccountAction>> _buildMenuItems(HosteDayUser? user) {
    final isAuthenticated = user?.hasEmail == true;

    if (isAuthenticated) {
      return const <PopupMenuEntry<_AccountAction>>[
        PopupMenuItem<_AccountAction>(
          value: _AccountAction.profile,
          child: Row(
            children: <Widget>[
              Icon(Icons.person_outline),
              SizedBox(width: 12),
              Text('Profile'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem<_AccountAction>(
          value: _AccountAction.logout,
          child: Row(
            children: <Widget>[
              Icon(Icons.logout),
              SizedBox(width: 12),
              Text('Sign out'),
            ],
          ),
        ),
      ];
    }

    return const <PopupMenuEntry<_AccountAction>>[
      PopupMenuItem<_AccountAction>(
        value: _AccountAction.login,
        child: Row(
          children: <Widget>[
            Icon(Icons.login),
            SizedBox(width: 12),
            Text('Sign in'),
          ],
        ),
      ),
      PopupMenuItem<_AccountAction>(
        value: _AccountAction.register,
        child: Row(
          children: <Widget>[
            Icon(Icons.person_add_outlined),
            SizedBox(width: 12),
            Text('Create account'),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: <Widget>[
        IconButton(
          tooltip: 'Home',
          onPressed: () => _goHome(context),
          icon: const Icon(Icons.home_outlined),
        ),
        StreamBuilder<HosteDayUser?>(
          stream: HosteDay.auth.authStateChanges(),
          initialData: HosteDay.auth.currentUser,
          builder: (context, snapshot) {
            final user = snapshot.data;
            final isAuthenticated = user?.hasEmail == true;

            return PopupMenuButton<_AccountAction>(
              tooltip: 'Account menu',
              icon: Icon(
                isAuthenticated
                    ? Icons.account_circle
                    : Icons.account_circle_outlined,
              ),
              onSelected: (action) async {
                await _handleAccountAction(context, action);
              },
              itemBuilder: (_) => _buildMenuItems(user),
            );
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
