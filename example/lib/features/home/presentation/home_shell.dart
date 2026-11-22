import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routes/go_page.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/presentation/pages/forgot_password_page.dart';
import '../../auth/presentation/pages/login_page.dart';
import '../../auth/presentation/pages/register_page.dart';
import '../../guide/presentation/pages/guide_page.dart';
import '../../settings/presentation/pages/settings_page.dart';
import '../../user/presentation/pages/password_reset_email_page.dart';
import '../../user/presentation/pages/profile_page.dart';
import '../../user/presentation/pages/verification_notification_page.dart';
import '../../live_bidding/views/live_bidding_screen.dart';
import '../controllers/home_controller.dart';

/// The central shell for the Hosteday boilerplate application.
///
/// Responsive layout powered by GetX:
/// - Desktop & Tablet (width >= 768px): Uses a side [NavigationRail] with Theme Switcher & Language Switcher.
/// - Mobile (width < 768px): Uses a bottom [NavigationBar] and standard [AppBar] with Theme & Language actions.
class HomeShell extends StatelessWidget {
  final HostedayUser? user;
  final HomeTab? initialTab;
  final Widget? child;

  const HomeShell({this.user, this.initialTab, this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController(), permanent: true);
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);

    return Obx(() {
      final currentUser = authController.currentUser.value ?? user;
      final isAuthenticated = currentUser != null;
      final selectedTab = initialTab ?? homeController.currentTab.value;

      final pageTitle = () {
        if (child is LoginPage) {
          return '${'sign_in'.tr} | Hosteday';
        } else if (child is RegisterPage) {
          return '${'create_account'.tr} | Hosteday';
        } else if (child is ForgotPasswordPage) {
          return '${'forgot_password_app_bar_title'.tr} | Hosteday';
        } else if (child is PasswordResetEmailPage) {
          return '${'password_reset_email_app_bar_title'.tr} | Hosteday';
        } else if (child is VerificationNotificationPage) {
          return '${'verification_notification_app_bar_title'.tr} | Hosteday';
        }

        return switch (selectedTab) {
          HomeTab.guide => '${'nav_guide'.tr} | Hosteday',
          HomeTab.realtime => '${'live_bidding_app_bar_title'.tr} | Hosteday',
          HomeTab.settings => '${'settings_title'.tr} | Hosteday',
          HomeTab.profile => '${'nav_profile'.tr} | Hosteday',
        };
      }();

      return Title(
        title: pageTitle,
        color: theme.colorScheme.primary,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth >= 768;
            final isLargeDesktop = constraints.maxWidth >= 1100;

            final activeTabBody =
                child ??
                switch (selectedTab) {
                  HomeTab.guide => GuidePage(
                    onNavigateToTab: homeController.setTabIndex,
                  ),
                  HomeTab.realtime =>
                    Hosteday.features.isRealtimeEnabled
                        ? const LiveBiddingScreen()
                        : FeaturePaywallPage.realtime(
                            onBack: () => homeController.setTabIndex(0),
                          ),
                  HomeTab.settings => const SettingsPage(),
                  HomeTab.profile =>
                    isAuthenticated
                        ? const ProfilePage()
                        : _buildUnauthenticatedProfileView(context, theme),
                };

            // -----------------------------------------------------------------
            // 1. Tablet & Desktop Layout: Side NavigationRail + Main Content
            // -----------------------------------------------------------------
            if (isWideScreen) {
              return Scaffold(
                body: Row(
                  children: <Widget>[
                    LayoutBuilder(
                      builder: (context, railConstraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: railConstraints.maxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: NavigationRail(
                                extended: isLargeDesktop,
                                selectedIndex: child != null
                                    ? (!isAuthenticated ? 3 : null)
                                    : selectedTab.index,
                                onDestinationSelected: (index) {
                                  if (!isAuthenticated) {
                                    if (index == 3) {
                                      GoPage.login();
                                      return;
                                    }
                                    homeController.setTabIndex(index);
                                  } else {
                                    if (index == 4) {
                                      authController.signOut();
                                      return;
                                    }
                                    homeController.setTabIndex(index);
                                  }
                                },
                                minExtendedWidth: 200,
                                leading: Container(
                                  width: isLargeDesktop ? 200.0 : 72.0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      SizedBox(
                                        width: 72.0,
                                        child: Center(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.asset(
                                              'assets/logo.png',
                                              width: 32,
                                              height: 32,
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      color: theme
                                                          .colorScheme
                                                          .primary
                                                          .withValues(
                                                            alpha: 0.15,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Icon(
                                                      Icons.bolt_rounded,
                                                      size: 20,
                                                      color: theme
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (isLargeDesktop) ...<Widget>[
                                        Expanded(
                                          child: Text(
                                            'starter_title'.tr,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18,
                                              letterSpacing: -0.3,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    ],
                                  ),
                                ),
                                trailing: Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 20,
                                      ),
                                      child: InkWell(
                                        onTap: () async {
                                          final uri = Uri.parse(
                                            'https://hosteday.com',
                                          );
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(
                                              uri,
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          child: isLargeDesktop
                                              ? Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: <Widget>[
                                                    Text(
                                                      'From ',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: theme
                                                            .colorScheme
                                                            .onSurface
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Hosteday',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: theme
                                                            .colorScheme
                                                            .primary,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Icon(
                                                      Icons.open_in_new_rounded,
                                                      size: 13,
                                                      color: theme
                                                          .colorScheme
                                                          .primary
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
                                                    ),
                                                  ],
                                                )
                                              : Tooltip(
                                                  message:
                                                      'From Hosteday (hosteday.com)',
                                                  child: Text(
                                                    'HD',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: theme
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                destinations: <NavigationRailDestination>[
                                  NavigationRailDestination(
                                    icon: const Icon(
                                      Icons.auto_stories_outlined,
                                    ),
                                    selectedIcon: const Icon(
                                      Icons.auto_stories,
                                    ),
                                    label: Text('nav_guide'.tr),
                                  ),
                                  NavigationRailDestination(
                                    icon: const Icon(Icons.radar_outlined),
                                    selectedIcon: const Icon(Icons.radar),
                                    label: Text(
                                      'live_bidding_app_bar_title'.tr,
                                    ),
                                  ),
                                  NavigationRailDestination(
                                    icon: const Icon(Icons.settings_outlined),
                                    selectedIcon: const Icon(Icons.settings),
                                    label: Text('nav_settings'.tr),
                                  ),
                                  if (!isAuthenticated)
                                    NavigationRailDestination(
                                      icon: const Icon(Icons.login_rounded),
                                      selectedIcon: const Icon(
                                        Icons.login_rounded,
                                      ),
                                      label: Text('sign_in'.tr),
                                    )
                                  else ...<NavigationRailDestination>[
                                    NavigationRailDestination(
                                      icon: const Icon(Icons.person_outline),
                                      selectedIcon: const Icon(Icons.person),
                                      label: Text('nav_profile'.tr),
                                    ),
                                    NavigationRailDestination(
                                      icon: const Icon(Icons.logout_rounded),
                                      selectedIcon: const Icon(
                                        Icons.logout_rounded,
                                      ),
                                      label: Text('sign_out'.tr),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const VerticalDivider(thickness: 1, width: 1),
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          if (isAuthenticated && !currentUser.isEmailVerified)
                            _buildEmailVerificationNotice(
                              context,
                              theme,
                              currentUser,
                              authController,
                            ),

                          Expanded(child: activeTabBody),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // -----------------------------------------------------------------
            // 2. Mobile Layout: Top AppBar + Main Content + Bottom Nav
            // -----------------------------------------------------------------
            return Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: Row(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.bolt_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'starter_title'.tr,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              body: Column(
                children: <Widget>[
                  if (isAuthenticated && !currentUser.isEmailVerified)
                    _buildEmailVerificationNotice(
                      context,
                      theme,
                      currentUser,
                      authController,
                    ),
                  Expanded(child: activeTabBody),
                ],
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: child != null
                    ? (!isAuthenticated ? 3 : 0)
                    : selectedTab.index,
                onDestinationSelected: (index) {
                  if (!isAuthenticated) {
                    if (index == 3) {
                      GoPage.login();
                      return;
                    }
                    homeController.setTabIndex(index);
                  } else {
                    if (index == 4) {
                      authController.signOut();
                      return;
                    }
                    homeController.setTabIndex(index);
                  }
                },
                destinations: <NavigationDestination>[
                  NavigationDestination(
                    icon: const Icon(Icons.auto_stories_outlined),
                    selectedIcon: const Icon(Icons.auto_stories),
                    label: 'nav_guide'.tr,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.radar_outlined),
                    selectedIcon: const Icon(Icons.radar),
                    label: 'live_bidding_app_bar_title'.tr,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.settings_outlined),
                    selectedIcon: const Icon(Icons.settings),
                    label: 'nav_settings'.tr,
                  ),
                  if (!isAuthenticated)
                    NavigationDestination(
                      icon: const Icon(Icons.login_rounded),
                      selectedIcon: const Icon(Icons.login_rounded),
                      label: 'sign_in'.tr,
                    )
                  else ...<NavigationDestination>[
                    NavigationDestination(
                      icon: const Icon(Icons.person_outline),
                      selectedIcon: const Icon(Icons.person),
                      label: 'nav_profile'.tr,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.logout_rounded),
                      selectedIcon: const Icon(Icons.logout_rounded),
                      label: 'sign_out'.tr,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildEmailVerificationNotice(
    BuildContext context,
    ThemeData theme,
    HostedayUser user,
    AuthController authController,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(
            color: Colors.amber.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 540;

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.mark_email_unread_outlined,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'email_unverified_banner_title'.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'email_unverified_banner_desc'.trParams({
                    'email': user.email ?? '',
                  }),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: Text(
                        'reload_status'.tr,
                        style: const TextStyle(fontSize: 11),
                      ),
                      onPressed: authController.reloadUser,
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: GoPage.verificationNotification,
                      child: Text(
                        'verify_now'.tr,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'email_unverified_long_title'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'email_unverified_long_desc'.trParams({
                        'email': user.email ?? '',
                      }),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.75,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
                onPressed: GoPage.verificationNotification,
                child: Text('verify_now'.tr),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'reload_status'.tr,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                visualDensity: VisualDensity.compact,
                onPressed: authController.reloadUser,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUnauthenticatedProfileView(
    BuildContext context,
    ThemeData theme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 960;
        final isTablet = width >= 640 && width < 960;
        final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 20.0 : 12.0);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.15,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.account_circle_outlined,
                                size: 36,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'auth_required_title'.tr,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'auth_required_desc'.tr,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: GoPage.login,
                            icon: const Icon(Icons.login_rounded),
                            label: Text('sign_in'.tr),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: GoPage.register,
                            icon: const Icon(Icons.person_add_outlined),
                            label: Text('create_account'.tr),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
