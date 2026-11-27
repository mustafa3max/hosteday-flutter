import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

const IconData _kNotificationsActiveIcon = IconData(
  0xf0026,
  fontFamily: 'MaterialIcons',
);
const IconData _kBoltIcon = IconData(0xf5ca, fontFamily: 'MaterialIcons');
const IconData _kStorageIcon = IconData(0xf01de, fontFamily: 'MaterialIcons');
const IconData _kLockClockIcon = IconData(0xf886, fontFamily: 'MaterialIcons');
const IconData _kArrowBackIcon = IconData(
  0xf572,
  fontFamily: 'MaterialIcons',
  matchTextDirection: true,
);
const IconData _kCheckCircleIcon =
    IconData(0xf635, fontFamily: 'MaterialIcons');
const IconData _kRocketLaunchIcon =
    IconData(0xf0372, fontFamily: 'MaterialIcons');

/// A dark-mode promotional paywall page displayed when a platform feature is
/// locked or not included in the current subscription plan.
class FeaturePaywallPage extends StatelessWidget {
  /// The technical identifier of the feature (e.g. 'push_notifications', 'realtime_websockets').
  final String featureKey;

  /// Optional custom title. If null, a formatted default title will be used.
  final String? title;

  /// Optional custom descriptive text.
  final String? description;

  /// Optional icon representing the feature.
  final IconData? icon;

  /// URL directed to for plan upgrades.
  final String upgradeUrl;

  /// Optional callback executed when clicking the upgrade button.
  /// If provided, this is called instead of launching [upgradeUrl].
  final VoidCallback? onUpgrade;

  /// Optional callback when user wants to go back.
  final VoidCallback? onBack;

  /// Feature highlight bullets to show why this feature is valuable.
  final List<String>? highlights;

  const FeaturePaywallPage({
    super.key,
    required this.featureKey,
    this.title,
    this.description,
    this.icon,
    this.upgradeUrl = 'https://hosteday.com/dashboard/plans',
    this.onUpgrade,
    this.onBack,
    this.highlights,
  });

  /// Factory helper for Push Notifications feature paywall.
  factory FeaturePaywallPage.notifications({
    Key? key,
    VoidCallback? onUpgrade,
    VoidCallback? onBack,
    String? upgradeUrl,
  }) {
    return FeaturePaywallPage(
      key: key,
      featureKey: 'push_notifications',
      icon: _kNotificationsActiveIcon,
      title: 'ميزة الإشعارات الفورية غير مفعلة في خطتك الحالية 🚀',
      description:
          'اربط تطبيقك مع خوادم Firebase و Apple Push وأرسل تنبيهات مخصصة لجمهورك بشكل فوري وفردي أو جماعي لزيادة التفاعل بنسبة تصل إلى 300%.',
      highlights: const [
        'إرسال إشعارات لحظية عبر أندرويد و iOS والويب',
        'استهداف مستخدمين محددين بناءً على حساباتهم ومعرفاتهم',
        'تقارير فورية بنسب الاستلام والفتح',
        'جدولة الحملات التسويقية والتنبيهات الدورية',
      ],
      upgradeUrl: upgradeUrl ?? 'https://hosteday.com/dashboard/plans',
      onUpgrade: onUpgrade,
      onBack: onBack,
    );
  }

  /// Factory helper for Realtime WebSockets feature paywall.
  factory FeaturePaywallPage.realtime({
    Key? key,
    VoidCallback? onUpgrade,
    VoidCallback? onBack,
    String? upgradeUrl,
  }) {
    return FeaturePaywallPage(
      key: key,
      featureKey: 'realtime_websockets',
      icon: _kBoltIcon,
      title: 'ميزة البث الحي المباشر (Realtime) غير مفعلة في خطتك ⚡',
      description:
          'فعّل قنوات الـ WebSockets المشفرة لدعم المحادثات الحية، والتحديثات الفورية، وإشارات الحضور (Presence) دون الحاجة لإعادة تحميل الشاشة.',
      highlights: const [
        'قنوات عامة، خاصة، وقنوات حضور (Presence Channels)',
        'تزامن بيانات فوري منخفض زمن الوصول (<50ms)',
        'إشعارات تفاعلية للمستخدمين المتصلين حالياً',
        'بنية تحتية موزعة ذات توفر عالٍ جاهزة للتوسع المليوني',
      ],
      upgradeUrl: upgradeUrl ?? 'https://hosteday.com/dashboard/plans',
      onUpgrade: onUpgrade,
      onBack: onBack,
    );
  }

  /// Factory helper for Database Management feature paywall.
  factory FeaturePaywallPage.database({
    Key? key,
    VoidCallback? onUpgrade,
    VoidCallback? onBack,
    String? upgradeUrl,
  }) {
    return FeaturePaywallPage(
      key: key,
      featureKey: 'database_management',
      icon: _kStorageIcon,
      title: 'ميزة إدارة قواعد البيانات المتقدمة غير مفعلة 🗄️',
      description:
          'استفد من خوادم قواعد البيانات السحابية المعزولة مع حزم نسخ احتياطي ذكية ومحددات وصول عالية الأمان.',
      highlights: const [
        'قواعد بيانات مخصصة لكل مستأجر مع عزل كامل',
        'نسخ احتياطي واستعادة آلية بنقرة زر',
        'فهارس متقدمة وتحليلات أداء الاستعلامات',
      ],
      upgradeUrl: upgradeUrl ?? 'https://hosteday.com/dashboard/plans',
      onUpgrade: onUpgrade,
      onBack: onBack,
    );
  }

  Future<void> _handleUpgrade() async {
    if (onUpgrade != null) {
      onUpgrade!();
      return;
    }

    final uri = Uri.parse(upgradeUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Failed to launch upgrade URL: $upgradeUrl');
      }
    } catch (_) {
      debugPrint('Failed to launch upgrade URL: $upgradeUrl');
    }
  }

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context);
    final isArabic = locale == null || locale.languageCode == 'ar';

    final effectiveTitle = title ??
        (isArabic
            ? 'ميزة $featureKey غير مفعلة في خطتك الحالية 🚀'
            : 'Feature "$featureKey" is locked on your plan 🚀');

    final effectiveDescription = description ??
        (isArabic
            ? 'هذه الميزة متاحة في باقات HosteDay المتقدمة. قم بترقية اشتراكك للاستفادة الكاملة من كافة إمكانيات المنصة السحابية.'
            : 'This feature is available on advanced HosteDay plans. Upgrade your subscription to unlock the full power of cloud features.');

    final effectiveIcon = icon ?? _kLockClockIcon;
    final canGoBack = Navigator.canPop(context) || onBack != null;

    return ColoredBox(
      color: const Color(0xFF0A0E1A),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          decoration: TextDecoration.none,
          fontFamilyFallback: ['Roboto', 'sans-serif'],
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (canGoBack)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _handleBack(context),
                        child: Semantics(
                          button: true,
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(
                              _kArrowBackIcon,
                              color: Color(0xFFFFFFFF),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final isDesktop = width >= 960;
                    final isTablet = width >= 640 && width < 960;
                    final horizontalPadding =
                        isDesktop ? 32.0 : (isTablet ? 20.0 : 12.0);

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
                              constraints: const BoxConstraints(maxWidth: 620),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Icon badge with glowing gradient ring
                                  Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF6366F1)
                                              .withValues(alpha: 0.3),
                                          const Color(0xFFEC4899)
                                              .withValues(alpha: 0.2),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(
                                        color: const Color(0xFF818CF8)
                                            .withValues(alpha: 0.4),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF6366F1)
                                              .withValues(alpha: 0.35),
                                          blurRadius: 32,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        effectiveIcon,
                                        size: 46,
                                        color: const Color(0xFFC7D2FE),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Plan status pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFF334155),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFF59E0B),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isArabic
                                              ? 'خطة غير مرخصة'
                                              : 'Plan Upgrade Required',
                                          style: const TextStyle(
                                            color: Color(0xFFE2E8F0),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Headline
                                  Text(
                                    effectiveTitle,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Descriptive subtitle
                                  Text(
                                    effectiveDescription,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 14,
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // Value highlights card
                                  if (highlights != null &&
                                      highlights!.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF131A2B),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFF1E293B),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isArabic
                                                ? 'ماذا ستحصل عند الترقية:'
                                                : 'What you unlock:',
                                            style: const TextStyle(
                                              color: Color(0xFFCBD5E1),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ...highlights!.map(
                                            (point) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Icon(
                                                    _kCheckCircleIcon,
                                                    size: 18,
                                                    color: Color(0xFF10B981),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      point,
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFFE2E8F0),
                                                        fontSize: 13,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 32),

                                  // CTA Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: _handleUpgrade,
                                        child: Semantics(
                                          button: true,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF6366F1),
                                                  Color(0xFF4F46E5),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF6366F1)
                                                      .withValues(alpha: 0.35),
                                                  blurRadius: 18,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      _kRocketLaunchIcon,
                                                      color: Color(0xFFFFFFFF),
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Flexible(
                                                      child: Text(
                                                        isArabic
                                                            ? 'ترقية الخطة الآن من لوحة تحكم HosteDay'
                                                            : 'Upgrade Plan in HosteDay Dashboard',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          color:
                                                              Color(0xFFFFFFFF),
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  if (canGoBack) ...[
                                    const SizedBox(height: 12),
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => _handleBack(context),
                                        child: Semantics(
                                          button: true,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            child: Text(
                                              isArabic
                                                  ? 'العودة للخلف'
                                                  : 'Go Back',
                                              style: const TextStyle(
                                                color: Color(0xFF94A3B8),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
