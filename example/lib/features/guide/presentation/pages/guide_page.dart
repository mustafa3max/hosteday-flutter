import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/localization/localization_controller.dart';
import '../../controllers/guide_controller.dart';
import '../../data/guide_content.dart';
import '../widgets/code_snippet_card.dart';

enum GuideCategory {
  all,
  starter,
  bootstrap,
  auth,
  api,
  realtime,
  notifications,
}

/// The official master showcase and responsive card-based guide for Hosteday apps using `GetView<GuideController>`.
class GuidePage extends GetView<GuideController> {
  final void Function(int tabIndex)? onNavigateToTab;

  const GuidePage({this.onNavigateToTab, super.key});

  List<GuideSection> _getFilteredSections(GuideCategory selectedCategory) {
    switch (selectedCategory) {
      case GuideCategory.all:
        return <GuideSection>[
          ...GuideContent.starterTemplateSections,
          ...GuideContent.bootstrapSections,
          ...GuideContent.authSections,
          ...GuideContent.apiSections,
          ...GuideContent.realtimeSections,
          ...GuideContent.notificationSections,
        ];
      case GuideCategory.starter:
        return GuideContent.starterTemplateSections;
      case GuideCategory.bootstrap:
        return GuideContent.bootstrapSections;
      case GuideCategory.auth:
        return GuideContent.authSections;
      case GuideCategory.api:
        return GuideContent.apiSections;
      case GuideCategory.realtime:
        return GuideContent.realtimeSections;
      case GuideCategory.notifications:
        return GuideContent.notificationSections;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final guideController = Get.isRegistered<GuideController>()
        ? Get.find<GuideController>()
        : Get.put(GuideController());

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
                    // 1. Hero Header
                    _buildHeroBanner(
                      theme,
                      isDesktop,
                      isArabic,
                      guideController,
                    ),
                    const SizedBox(height: 16),

                    // 2. Category Filter Chips
                    _buildCategoryFilterRow(
                      isArabic,
                      selectedCategory,
                      guideController,
                    ),
                    const SizedBox(height: 16),

                    // 3. Responsive Content Cards
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
    GuideController guideController,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 22 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            theme.colorScheme.primary.withValues(alpha: 0.12),
            const Color(0xFF1B1B22),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.code_rounded,
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
                  ButtonSegment<bool>(value: true, label: Text('arabic'.tr)),
                  ButtonSegment<bool>(value: false, label: Text('english'.tr)),
                ],
                selected: <bool>{isArabic},
                onSelectionChanged: (selection) {
                  guideController.setLanguage(selection.first);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'guide_hero_title'.tr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'guide_hero_subtitle'.tr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterRow(
    bool isArabic,
    GuideCategory selectedCategory,
    GuideController guideController,
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
            onSelected: () =>
                guideController.toggleCategory(GuideCategory.starter),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'category_bootstrap'.tr,
            category: GuideCategory.bootstrap,
            isSelected: selectedCategory == GuideCategory.bootstrap,
            onSelected: () =>
                guideController.toggleCategory(GuideCategory.bootstrap),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'category_auth'.tr,
            category: GuideCategory.auth,
            isSelected: selectedCategory == GuideCategory.auth,
            onSelected: () =>
                guideController.toggleCategory(GuideCategory.auth),
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
            onSelected: () =>
                guideController.toggleCategory(GuideCategory.realtime),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'category_notifications'.tr,
            category: GuideCategory.notifications,
            isSelected: selectedCategory == GuideCategory.notifications,
            onSelected: () =>
                guideController.toggleCategory(GuideCategory.notifications),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoColumnResponsiveCards(
    List<GuideSection> sections,
    bool isArabic,
  ) {
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
