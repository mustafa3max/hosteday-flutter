import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/localization/localization_controller.dart';
import '../../../../core/routes/go_page.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../controllers/example_guide_controller.dart';
import '../../data/example_guide_content.dart';
import '../widgets/code_snippet_card.dart';
import '../widgets/platform_capability_card.dart';

enum GuideCategory {
  all,
  starter,
  bootstrap,
  auth,
  api,
  realtime,
  notifications,
}

/// The official master showcase and responsive card-based guide for Hosteday apps using `GetView<ExampleGuideController>`.
class ExampleGuidePage extends GetView<ExampleGuideController> {
  final void Function(int tabIndex)? onNavigateToTab;

  const ExampleGuidePage({this.onNavigateToTab, super.key});

  List<GuideSection> _getFilteredSections(GuideCategory selectedCategory) {
    switch (selectedCategory) {
      case GuideCategory.all:
        return <GuideSection>[
          ...ExampleGuideContent.starterTemplateSections,
          ...ExampleGuideContent.bootstrapSections,
          ...ExampleGuideContent.authSections,
          ...ExampleGuideContent.apiSections,
          ...ExampleGuideContent.realtimeSections,
          ...ExampleGuideContent.notificationSections,
        ];
      case GuideCategory.starter:
        return ExampleGuideContent.starterTemplateSections;
      case GuideCategory.bootstrap:
        return ExampleGuideContent.bootstrapSections;
      case GuideCategory.auth:
        return ExampleGuideContent.authSections;
      case GuideCategory.api:
        return ExampleGuideContent.apiSections;
      case GuideCategory.realtime:
        return ExampleGuideContent.realtimeSections;
      case GuideCategory.notifications:
        return ExampleGuideContent.notificationSections;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final guideController = Get.isRegistered<ExampleGuideController>()
        ? Get.find<ExampleGuideController>()
        : Get.put(ExampleGuideController());

    final localizationController = Get.isRegistered<LocalizationController>()
        ? LocalizationController.to
        : null;

    return Obx(() {
      final isArabic = localizationController?.isArabic ?? true;
      final selectedCategory = guideController.selectedCategory.value;
      final sections = _getFilteredSections(selectedCategory);

      return Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= 960;
            final isTablet = width >= 640 && width < 960;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : (isTablet ? 20 : 12),
                    vertical: 16,
                  ),
                  children: <Widget>[
                    // 1. Hero Banner
                    _buildHeroBanner(theme, isDesktop, isArabic, guideController),
                    const SizedBox(height: 18),

                    // Live Bidding Radar Feature Card
                    _buildLiveBiddingCard(theme, isArabic, width < 600),
                    const SizedBox(height: 18),

                    // 2. Responsive Platform Capability Overview Cards (Grid)
                    _buildCapabilityCardsGrid(width, isArabic, selectedCategory, guideController),
                    const SizedBox(height: 18),

                    // 3. Auth & Profile Interactive Status Card
                    _buildAuthStatusCard(theme, width >= 680, isArabic),
                    const SizedBox(height: 20),

                    // 4. Category Filter Chips
                    _buildCategoryFilterRow(isArabic, selectedCategory, guideController),
                    const SizedBox(height: 18),

                    // 5. Responsive Content Cards
                    if (width < 768) ...<Widget>[
                      ...sections.map(
                        (section) => SizedBox(
                          width: double.infinity,
                          child: CodeSnippetCard(
                            category: isArabic
                                ? section.categoryAr
                                : section.categoryEn,
                            icon: section.icon,
                            title: isArabic ? section.titleAr : section.titleEn,
                            description: isArabic
                                ? section.descriptionAr
                                : section.descriptionEn,
                            code: section.code,
                            language: section.language,
                          ),
                        ),
                      ),
                    ] else ...<Widget>[
                      _buildTwoColumnResponsiveCards(sections, isArabic),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildHeroBanner(
    ThemeData theme,
    bool isDesktop,
    bool isArabic,
    ExampleGuideController guideController,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 24 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            theme.colorScheme.primary.withValues(alpha: 0.16),
            const Color(0xFF1B1B22),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.architecture_rounded,
                      size: 15,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'guide_hero_badge'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Language Segmented Control
              SegmentedButton<bool>(
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                segments: <ButtonSegment<bool>>[
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('arabic'.tr),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('english'.tr),
                  ),
                ],
                selected: <bool>{isArabic},
                onSelectionChanged: (selection) {
                  guideController.setLanguage(selection.first);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'guide_hero_title'.tr,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'guide_hero_subtitle'.tr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ActionChip(
                avatar: const Icon(Icons.radar_rounded, size: 16, color: Color(0xFFF59E0B)),
                label: Text(isArabic ? 'رادار المزايدة الحية (Live Bidding)' : 'Live Bidding Radar'),
                backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                side: const BorderSide(color: Color(0xFFF59E0B), width: 1),
                onPressed: GoPage.liveBidding,
              ),
              ActionChip(
                avatar: const Icon(Icons.notifications_outlined, size: 16),
                label: Text('nav_notifications'.tr),
                onPressed: () => onNavigateToTab?.call(2),
              ),
              ActionChip(
                avatar: const Icon(Icons.person_outline, size: 16),
                label: Text('nav_profile'.tr),
                onPressed: () => onNavigateToTab?.call(3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBiddingCard(ThemeData theme, bool isArabic, bool isNarrow) {
    final title = isArabic
        ? 'رادار المزايدة الحية والتحدي الصامت'
        : 'Live Bidding Radar & Silent Challenge';
    final subtitle = isArabic
        ? 'ميزة تفاعلية بالكامل معتمدة على Presence Channels والهمس اللحظي (Whisper) و FCM v1'
        : 'Fully interactive feature powered by Presence Channels, Whisper events & FCM v1';
    final buttonLabel = isArabic ? 'دخول ساحة المزاد' : 'Enter Auction Arena';

    final iconWidget = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: const Icon(
        Icons.radar_rounded,
        color: Color(0xFFFBBF24),
        size: 26,
      ),
    );

    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.circle, size: 7, color: Color(0xFF34D399)),
                  SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );

    final actionButton = FilledButton.icon(
      onPressed: GoPage.liveBidding,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      icon: const Icon(Icons.flash_on_rounded, size: 16),
      label: Text(
        buttonLabel,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF151522), Color(0xFF22160F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    iconWidget,
                    const SizedBox(width: 12),
                    Expanded(child: textColumn),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: actionButton,
                ),
              ],
            )
          : Row(
              children: <Widget>[
                iconWidget,
                const SizedBox(width: 14),
                Expanded(child: textColumn),
                const SizedBox(width: 14),
                actionButton,
              ],
            ),
    );
  }

  Widget _buildCapabilityCardsGrid(
    double screenWidth,
    bool isArabic,
    GuideCategory selectedCategory,
    ExampleGuideController guideController,
  ) {
    final cards = <Widget>[
      PlatformCapabilityCard(
        icon: Icons.lock_person_rounded,
        title: 'cap_auth_title'.tr,
        subtitle: 'cap_auth_subtitle'.tr,
        accentColor: const Color(0xFF60A5FA),
        isSelected: selectedCategory == GuideCategory.auth,
        onTap: () => guideController.toggleCategory(GuideCategory.auth),
      ),
      PlatformCapabilityCard(
        icon: Icons.dns_rounded,
        title: 'cap_api_title'.tr,
        subtitle: 'cap_api_subtitle'.tr,
        accentColor: const Color(0xFF34D399),
        isSelected: selectedCategory == GuideCategory.api,
        onTap: () => guideController.toggleCategory(GuideCategory.api),
      ),
      PlatformCapabilityCard(
        icon: Icons.bolt_rounded,
        title: 'cap_realtime_title'.tr,
        subtitle: 'cap_realtime_subtitle'.tr,
        accentColor: const Color(0xFFFBBF24),
        isSelected: selectedCategory == GuideCategory.realtime,
        onTap: () => guideController.toggleCategory(GuideCategory.realtime),
      ),
      PlatformCapabilityCard(
        icon: Icons.notifications_active_rounded,
        title: 'cap_notifications_title'.tr,
        subtitle: 'cap_notifications_subtitle'.tr,
        accentColor: const Color(0xFFF472B6),
        isSelected: selectedCategory == GuideCategory.notifications,
        onTap: () => guideController.toggleCategory(GuideCategory.notifications),
      ),
    ];

    if (screenWidth >= 960) {
      return Row(
        children: cards
            .map(
              (card) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: card,
                ),
              ),
            )
            .toList(),
      );
    } else if (screenWidth >= 560) {
      return Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: cards[0]),
              const SizedBox(width: 10),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(child: cards[2]),
              const SizedBox(width: 10),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: cards
            .map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: card,
                ),
              ),
            )
            .toList(),
      );
    }
  }

  Widget _buildAuthStatusCard(ThemeData theme, bool isWide, bool isArabic) {
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);

    return Obx(() {
      final user = authController.currentUser.value;
      final isAuth = user != null;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAuth
                ? theme.colorScheme.primary.withValues(alpha: 0.45)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
        child: isWide
            ? Row(
                children: <Widget>[
                  Icon(
                    isAuth
                        ? (user.isEmailVerified
                            ? Icons.verified_user_rounded
                            : Icons.mark_email_unread_rounded)
                        : Icons.lock_person_outlined,
                    size: 28,
                    color: isAuth
                        ? (user.isEmailVerified
                            ? theme.colorScheme.primary
                            : Colors.amber)
                        : Colors.amber,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                isAuth
                                    ? 'interactive_status_authenticated'.trParams({
                                        'email': user.displayName ?? user.email ?? '',
                                      })
                                    : 'interactive_status_guest'.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isAuth) ...<Widget>[
                              const SizedBox(width: 8),
                              _buildEmailVerificationBadge(
                                user.isEmailVerified,
                                isArabic,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isAuth
                              ? (user.isEmailVerified
                                  ? 'verification_verified_desc'.tr
                                  : 'email_unverified_long_desc'.trParams({
                                      'email': user.email ?? '',
                                    }))
                              : 'auth_required_desc'.tr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isAuth && !user.isEmailVerified
                                ? Colors.amber.shade400
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildAuthButtons(
                    isAuth,
                    isArabic,
                    isRow: true,
                    isEmailVerified: user?.isEmailVerified ?? false,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        isAuth
                            ? (user.isEmailVerified
                                ? Icons.verified_user_rounded
                                : Icons.mark_email_unread_rounded)
                            : Icons.lock_person_outlined,
                        size: 22,
                        color: isAuth
                            ? (user.isEmailVerified
                                ? theme.colorScheme.primary
                                : Colors.amber)
                            : Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isAuth
                              ? 'interactive_status_authenticated'.trParams({
                                  'email': user.displayName ?? user.email ?? '',
                                })
                              : 'interactive_status_guest'.tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (isAuth) ...<Widget>[
                        const SizedBox(width: 6),
                        _buildEmailVerificationBadge(
                          user.isEmailVerified,
                          isArabic,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAuth
                        ? (user.isEmailVerified
                            ? 'verification_verified_desc'.tr
                            : 'email_unverified_long_desc'.trParams({
                                'email': user.email ?? '',
                              }))
                        : 'auth_required_desc'.tr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isAuth && !user.isEmailVerified
                          ? Colors.amber.shade400
                          : theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAuthButtons(
                    isAuth,
                    isArabic,
                    isRow: false,
                    isEmailVerified: user?.isEmailVerified ?? false,
                  ),
                ],
              ),
      );
    });
  }

  Widget _buildEmailVerificationBadge(bool isVerified, bool isArabic) {
    final color = isVerified ? const Color(0xFF10B981) : Colors.amber;
    return InkWell(
      onTap: isVerified ? null : GoPage.verificationNotification,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              isVerified
                  ? Icons.check_circle_rounded
                  : Icons.warning_amber_rounded,
              size: 13,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              isVerified
                  ? 'email_verified_status'.tr
                  : 'email_unverified_status'.tr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthButtons(
    bool isAuth,
    bool isArabic, {
    bool isRow = false,
    bool isEmailVerified = true,
  }) {
    final buttons = isAuth
        ? <Widget>[
            if (!isEmailVerified) ...<Widget>[
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: GoPage.verificationNotification,
                icon: const Icon(Icons.mark_email_unread_outlined, size: 16),
                label: Text('verify_now'.tr),
              ),
              if (isRow) const SizedBox(width: 8),
            ],
            FilledButton.tonalIcon(
              onPressed: () => onNavigateToTab?.call(3),
              icon: const Icon(Icons.person_outline, size: 16),
              label: Text('nav_profile'.tr),
            ),
            if (isRow) const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final authController = Get.isRegistered<AuthController>()
                    ? Get.find<AuthController>()
                    : Get.put(AuthController(), permanent: true);
                await authController.signOut();
              },
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: Text('sign_out'.tr),
            ),
          ]
        : <Widget>[
            FilledButton.icon(
              onPressed: GoPage.login,
              icon: const Icon(Icons.login_rounded, size: 16),
              label: Text('sign_in'.tr),
            ),
            if (isRow) const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: GoPage.register,
              icon: const Icon(Icons.person_add_outlined, size: 16),
              label: Text('create_account'.tr),
            ),
          ];

    if (isRow) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: buttons,
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: buttons,
    );
  }

  Widget _buildCategoryFilterRow(
    bool isArabic,
    GuideCategory selectedCategory,
    ExampleGuideController guideController,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _buildFilterChip(
            label: 'all_categories'.tr,
            category: GuideCategory.all,
            isSelected: selectedCategory == GuideCategory.all,
            onSelected: () => guideController.toggleCategory(GuideCategory.all),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'category_starter'.tr,
            category: GuideCategory.starter,
            isSelected: selectedCategory == GuideCategory.starter,
            onSelected: () => guideController.toggleCategory(GuideCategory.starter),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'category_bootstrap'.tr,
            category: GuideCategory.bootstrap,
            isSelected: selectedCategory == GuideCategory.bootstrap,
            onSelected: () => guideController.toggleCategory(GuideCategory.bootstrap),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'category_auth'.tr,
            category: GuideCategory.auth,
            isSelected: selectedCategory == GuideCategory.auth,
            onSelected: () => guideController.toggleCategory(GuideCategory.auth),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'category_api'.tr,
            category: GuideCategory.api,
            isSelected: selectedCategory == GuideCategory.api,
            onSelected: () => guideController.toggleCategory(GuideCategory.api),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'category_realtime'.tr,
            category: GuideCategory.realtime,
            isSelected: selectedCategory == GuideCategory.realtime,
            onSelected: () => guideController.toggleCategory(GuideCategory.realtime),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'category_notifications'.tr,
            category: GuideCategory.notifications,
            isSelected: selectedCategory == GuideCategory.notifications,
            onSelected: () => guideController.toggleCategory(GuideCategory.notifications),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoColumnResponsiveCards(List<GuideSection> sections, bool isArabic) {
    final leftColumn = <GuideSection>[];
    final rightColumn = <GuideSection>[];

    for (var i = 0; i < sections.length; i++) {
      if (i.isEven) {
        leftColumn.add(sections[i]);
      } else {
        rightColumn.add(sections[i]);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: leftColumn
                .map(
                  (section) => CodeSnippetCard(
                    category:
                        isArabic ? section.categoryAr : section.categoryEn,
                    icon: section.icon,
                    title: isArabic ? section.titleAr : section.titleEn,
                    description: isArabic
                        ? section.descriptionAr
                        : section.descriptionEn,
                    code: section.code,
                    language: section.language,
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rightColumn
                .map(
                  (section) => CodeSnippetCard(
                    category:
                        isArabic ? section.categoryAr : section.categoryEn,
                    icon: section.icon,
                    title: isArabic ? section.titleAr : section.titleEn,
                    description: isArabic
                        ? section.descriptionAr
                        : section.descriptionEn,
                    code: section.code,
                    language: section.language,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required GuideCategory category,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
    );
  }
}
