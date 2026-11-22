import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../../core/localization/localization_controller.dart';
import '../../core/routes/go_page.dart';

enum _AccountAction { login, register, profile, logout }

/// Shared application AppBar with account menu, language toggle, and navigation actions.
class AppBarMy extends StatelessWidget implements PreferredSizeWidget {
  final String? title;

  const AppBarMy({this.title, super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _goHome(BuildContext context) {
    GoPage.offHome();
  }

  Future<void> _openLogin(BuildContext context) async {
    await GoPage.login();
  }

  Future<void> _openRegister(BuildContext context) async {
    await GoPage.register();
  }

  Future<void> _openProfile(BuildContext context) async {
    await GoPage.profile(showAppBar: true);
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await Hosteday.client.auth.signOut();

      if (!context.mounted) {
        return;
      }

      GoPage.offHome();
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'sign_out_failed'.trParams({'error': error.toString()}),
          ),
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

  List<PopupMenuEntry<_AccountAction>> _buildMenuItems(HostedayUser? user) {
    final isAuthenticated = user?.hasEmail == true;

    if (isAuthenticated) {
      return <PopupMenuEntry<_AccountAction>>[
        PopupMenuItem<_AccountAction>(
          value: _AccountAction.profile,
          child: Row(
            children: <Widget>[
              const Icon(Icons.person_outline),
              const SizedBox(width: 12),
              Text('nav_profile'.tr),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<_AccountAction>(
          value: _AccountAction.logout,
          child: Row(
            children: <Widget>[
              const Icon(Icons.logout),
              const SizedBox(width: 12),
              Text('sign_out'.tr),
            ],
          ),
        ),
      ];
    }

    return <PopupMenuEntry<_AccountAction>>[
      PopupMenuItem<_AccountAction>(
        value: _AccountAction.login,
        child: Row(
          children: <Widget>[
            const Icon(Icons.login),
            const SizedBox(width: 12),
            Text('sign_in'.tr),
          ],
        ),
      ),
      PopupMenuItem<_AccountAction>(
        value: _AccountAction.register,
        child: Row(
          children: <Widget>[
            const Icon(Icons.person_add_outlined),
            const SizedBox(width: 12),
            Text('create_account'.tr),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title ?? 'starter_title'.tr),
      actions: <Widget>[
        // Language switcher
        IconButton(
          tooltip: 'switch_language'.tr,
          onPressed: () {
            if (Get.isRegistered<LocalizationController>()) {
              LocalizationController.to.toggleLanguage();
            }
          },
          icon: const Icon(Icons.language_rounded),
        ),
        IconButton(
          tooltip: 'home'.tr,
          onPressed: () => _goHome(context),
          icon: const Icon(Icons.home_outlined),
        ),
        StreamBuilder<HostedayUser?>(
          stream: Hosteday.auth.authStateChanges(),
          initialData: Hosteday.auth.currentUser,
          builder: (context, snapshot) {
            final user = snapshot.data;
            final isAuthenticated = user?.hasEmail == true;

            return PopupMenuButton<_AccountAction>(
              tooltip: 'account_menu'.tr,
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
