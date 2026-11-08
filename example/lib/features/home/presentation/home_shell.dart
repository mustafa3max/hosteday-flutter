import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../../../core/localization/localization_controller.dart';
import '../../../core/routes/go_page.dart';
import '../../../core/theme/theme_picker_sheet.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../example/presentation/pages/example_guide_page.dart';
import '../../notifications/presentation/pages/notifications_page.dart';
import '../../user/presentation/pages/profile_page.dart';
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

  const HomeShell({this.user, this.initialTab, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController(), permanent: true);
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);
    final localizationController = Get.isRegistered<LocalizationController>()
        ? LocalizationController.to
        : null;

    if (initialTab != null && homeController.currentTab.value != initialTab) {
      homeController.currentTab.value = initialTab!;
    }

    return Obx(() {
      final currentUser = authController.currentUser.value ?? user;
      final isAuthenticated = currentUser != null;
      final selectedTab = homeController.currentTab.value;

      return LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth >= 768;
          final isLargeDesktop = constraints.maxWidth >= 1100;

          final activeTabBody = switch (selectedTab) {
            HomeTab.example => ExampleGuidePage(
                onNavigateToTab: homeController.setTabIndex,
              ),
            HomeTab.realtime => Hosteday.features.isRealtimeEnabled
                ? const LiveBiddingScreen()
                : FeaturePaywallPage.realtime(
                    onBack: () => homeController.setTabIndex(0),
                  ),
            HomeTab.notifications => Hosteday.features.isNotificationsEnabled
                ? const NotificationsPage()
                : FeaturePaywallPage.notifications(
                    onBack: () => homeController.setTabIndex(0),
                  ),
            HomeTab.profile => isAuthenticated
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
                  NavigationRail(
                    extended: isLargeDesktop,
                    selectedIndex: homeController.selectedIndex,
                    onDestinationSelected: homeController.setTabIndex,
                    minExtendedWidth: 200,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.bolt_rounded,
                              size: 22,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          if (isLargeDesktop) ...<Widget>[
                            const SizedBox(width: 10),
                            Text(
                              'starter_title'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    trailing: Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              // Language Switcher in NavigationRail
                              if (localizationController != null)
                                if (isLargeDesktop)
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                    ),
                                    onPressed:
                                        localizationController.toggleLanguage,
                                    icon: const Icon(Icons.language_rounded,
                                        size: 16),
                                    label: Text(localizationController
                                        .targetLanguageName),
                                  )
                                else
                                  IconButton(
                                    tooltip: 'switch_language'.tr,
                                    onPressed:
                                        localizationController.toggleLanguage,
                                    icon: const Icon(Icons.language_rounded),
                                  ),
                              const SizedBox(height: 8),

                              // Theme Switcher in NavigationRail
                              if (isLargeDesktop)
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                  ),
                                  onPressed: () =>
                                      ThemePickerSheet.show(context),
                                  icon: const Icon(Icons.palette_outlined,
                                      size: 16),
                                  label: Text('theme_label'.tr),
                                )
                              else
                                IconButton(
                                  tooltip: 'change_theme'.tr,
                                  onPressed: () =>
                                      ThemePickerSheet.show(context),
                                  icon: const Icon(Icons.palette_outlined),
                                ),
                              const SizedBox(height: 10),

                              // Auth Action Button
                              if (isAuthenticated)
                                (isLargeDesktop
                                    ? OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: authController.signOut,
                                        icon: const Icon(Icons.logout_rounded,
                                            size: 16),
                                        label: Text('sign_out'.tr),
                                      )
                                    : IconButton(
                                        tooltip: 'sign_out'.tr,
                                        onPressed: authController.signOut,
                                        icon: const Icon(Icons.logout_rounded),
                                      ))
                              else
                                (isLargeDesktop
                                    ? FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: GoPage.login,
                                        icon: const Icon(Icons.login_rounded,
                                            size: 16),
                                        label: Text('sign_in'.tr),
                                      )
                                    : IconButton(
                                        tooltip: 'sign_in'.tr,
                                        onPressed: GoPage.login,
                                        icon: const Icon(Icons.login_rounded),
                                      )),
                            ],
                          ),
                        ),
                      ),
                    ),
                    destinations: <NavigationRailDestination>[
                      NavigationRailDestination(
                        icon: const Icon(Icons.auto_stories_outlined),
                        selectedIcon: const Icon(Icons.auto_stories),
                        label: Text('nav_guide'.tr),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.radar_outlined),
                        selectedIcon: const Icon(Icons.radar),
                        label: const Text('رادار المزاد'),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.notifications_outlined),
                        selectedIcon: const Icon(Icons.notifications),
                        label: Text('nav_notifications'.tr),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.person_outline),
                        selectedIcon: const Icon(Icons.person),
                        label: Text('nav_profile'.tr),
                      ),
                    ],
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
              title: Row(
                children: <Widget>[
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.bolt_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAuthenticated
                          ? (currentUser.displayName?.isNotEmpty == true
                              ? currentUser.displayName!
                              : (currentUser.email ?? 'starter_title'.tr))
                          : 'starter_title'.tr,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                // Live Bidding Radar Action Button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      foregroundColor: const Color(0xFFFBBF24),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      minimumSize: const Size(0, 34),
                    ),
                    onPressed: GoPage.liveBidding,
                    icon: const Icon(Icons.radar_rounded, size: 16, color: Color(0xFFF59E0B)),
                    label: const Text(
                      'رادار المزاد',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Mobile Language Switcher Action
                if (localizationController != null)
                  IconButton(
                    tooltip: 'switch_language'.tr,
                    onPressed: localizationController.toggleLanguage,
                    icon: const Icon(Icons.language_rounded),
                  ),
                // Mobile Theme Switcher Action
                IconButton(
                  tooltip: 'change_theme'.tr,
                  onPressed: () => ThemePickerSheet.show(context),
                  icon: const Icon(Icons.palette_outlined),
                ),
                if (!isAuthenticated) ...<Widget>[
                  TextButton.icon(
                    onPressed: GoPage.login,
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: Text('sign_in'.tr),
                  ),
                  const SizedBox(width: 8),
                ] else ...<Widget>[
                  IconButton(
                    tooltip: 'sign_out'.tr,
                    onPressed: authController.signOut,
                    icon: const Icon(Icons.logout_rounded),
                  ),
                ],
              ],
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
              selectedIndex: homeController.selectedIndex,
              onDestinationSelected: homeController.setTabIndex,
              destinations: <NavigationDestination>[
                NavigationDestination(
                  icon: const Icon(Icons.auto_stories_outlined),
                  selectedIcon: const Icon(Icons.auto_stories),
                  label: 'nav_guide'.tr,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.radar_outlined),
                  selectedIcon: const Icon(Icons.radar),
                  label: 'رادار المزاد',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.notifications_outlined),
                  selectedIcon: const Icon(Icons.notifications),
                  label: 'nav_notifications'.tr,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(Icons.person),
                  label: 'nav_profile'.tr,
                ),
              ],
            ),
          );
        },
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
                  'email_unverified_banner_desc'.trParams({'email': user.email ?? ''}),
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
                      'email_unverified_long_desc'.trParams({'email': user.email ?? ''}),
                      style: TextStyle(
                        fontSize: 11.5,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.75),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
      BuildContext context, ThemeData theme) {
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
                  horizontal: horizontalPadding, vertical: 24),
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
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.15),
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
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
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
