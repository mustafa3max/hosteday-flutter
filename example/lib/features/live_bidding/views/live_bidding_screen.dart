import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/live_bidding_controller.dart';
import 'widgets/active_bidders_bar.dart';
import 'widgets/bidding_controls.dart';
import 'widgets/real_time_logs_card.dart';

/// Full interactive screen for the "رادار المزايدة الحية والتحدي الصامت"
/// (Live Bidding Radar) feature.
class LiveBiddingScreen extends GetView<LiveBiddingController> {
  const LiveBiddingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!Get.isRegistered<LiveBiddingController>()) {
      Get.put(LiveBiddingController());
    }
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101018),
        elevation: 0,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Get.back();
                  }
                },
              )
            : null,
        title: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.radar_rounded,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'رادار المزايدة الحية (Live Bidding)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Obx(() => Text(
                        controller.auctionTitle.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          // WebSocket Connection Status Pill
          Obx(() {
            final isConnected = controller.isConnected.value;
            final isConnecting = controller.isConnecting.value;

            return Center(
              child: Container(
                margin: const EdgeInsets.only(left: 12, right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isConnected
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : (isConnecting
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                          : const Color(0xFFEF4444).withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isConnected
                        ? const Color(0xFF10B981).withValues(alpha: 0.4)
                        : (isConnecting
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                            : const Color(0xFFEF4444).withValues(alpha: 0.4)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isConnected
                            ? const Color(0xFF10B981)
                            : (isConnecting
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFEF4444)),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isConnected
                          ? 'الويب سوكت متصل'
                          : (isConnecting ? 'جاري الاتصال...' : 'غير متصل'),
                      style: TextStyle(
                        color: isConnected
                            ? const Color(0xFF34D399)
                            : (isConnecting
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFF87171)),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1024;
          final isTablet = constraints.maxWidth >= 600 && !isDesktop;
          final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 20.0 : 12.0);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  32,
                ),
                children: <Widget>[
                  // 0. Introductory Explanation Card (Channels & FCM Lab)
                  _buildIntroExplanationCard(context),

                  // 1. Presence Radar Bar
                  const ActiveBiddersBar(),
                  const SizedBox(height: 16),

                  // 2. Outbid Alert Banner (Reactive)
                  Obx(() {
                    if (!controller.hasOutbidNotice.value) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFF87171),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'تنبيه: تم كسر عرضك!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  controller.lastOutbidMessage.value,
                                  style: const TextStyle(
                                    color: Color(0xFFFCA5A5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => controller.submitBid(50),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'استعد الصدارة (+50\$)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // 3. Main Auction Arena Card
                  _buildAuctionArenaCard(context, theme),
                  const SizedBox(height: 16),

                  // 4. Bidding Controls
                  const BiddingControls(),
                  const SizedBox(height: 16),

                  // 5. Real-Time Activity Feed
                  const RealTimeLogsCard(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAuctionArenaCard(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF262636),
          width: 1,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          // Top Row: Status Pill and Countdown Timer
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.flash_on_rounded,
                      color: Color(0xFF38BDF8),
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'تحدي المزايدة الصامت (Live Whisper)',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Countdown Timer
              Obx(() {
                final time = controller.formatCountdown(
                  controller.remainingSeconds.value,
                );
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.timer_outlined,
                        color: Color(0xFFF59E0B),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ينتهي خلال: $time',
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 24),

          // Highest Bid Value with Pulse Animation
          Obx(() {
            final isPulsing = controller.isPulsing.value;
            final amount = controller.currentHighestBid.value;

            return AnimatedScale(
              scale: isPulsing ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isPulsing
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: isPulsing
                      ? Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.6),
                          width: 2,
                        )
                      : null,
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      'أعلى عرض حالي (Highest Bid)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\$$amount',
                      style: TextStyle(
                        color: isPulsing
                            ? const Color(0xFF34D399)
                            : const Color(0xFF10B981),
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          // Leader Pill
          Obx(() {
            final leaderName = controller.highestBidderName.value;
            final isSelf = controller.isCurrentHighestBidder;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelf
                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                    : const Color(0xFF262636),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelf
                      ? const Color(0xFF10B981).withValues(alpha: 0.4)
                      : const Color(0xFF374151),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    isSelf ? '👑 أنت متصدر المزاد حالياً' : 'المتصدر الحالي: $leaderName',
                    style: TextStyle(
                      color: isSelf ? const Color(0xFF34D399) : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildIntroExplanationCard(BuildContext context) {
    final isAuth = controller.isAuthenticated;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF141422),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C2E),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.cell_tower_rounded,
                        color: Color(0xFF818CF8),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'منصة اختبار الاتصال المباشر (Real-Time & Channels Lab)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'اختبار القنوات الثلاث (العامة، الخاصة، التواجد) وتجربة الإشعارات الفورية',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Identity status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isAuth
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAuth
                          ? const Color(0xFF10B981).withValues(alpha: 0.4)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        isAuth
                            ? Icons.verified_user_rounded
                            : Icons.person_outline_rounded,
                        size: 14,
                        color: isAuth
                            ? const Color(0xFF34D399)
                            : const Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isAuth
                            ? 'مسجل دخول: ${controller.currentUserName}'
                            : 'وضع الزائر (غير مسجل)',
                        style: TextStyle(
                          color: isAuth
                              ? const Color(0xFF34D399)
                              : const Color(0xFFFBBF24),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'توضح هذه الصفحة كيفية عمل وتبادل البيانات لحظياً عبر الويب سوكت (WebSockets) في خوادم HosteDay، وتوفر بيئة حية لفحص القنوات الثلاث واستقبال تنبيهات الـ Push:',
                  style: TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),

                // Channels Pillars
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 680;
                    final items = <Widget>[
                      _buildChannelPillar(
                        icon: Icons.public_rounded,
                        iconColor: const Color(0xFF3B82F6),
                        title: '1. القنوات العامة (Public Channels)',
                        badge: 'مفتوحة للجميع',
                        badgeColor: const Color(0xFF3B82F6),
                        description:
                            'تعمل تلقائياً لجميع المستخدمين والزوار دون الحاجة لتسجيل دخول. تُبث عبرها إعلانات حالة المزاد والتحديثات الجماعية.',
                      ),
                      _buildChannelPillar(
                        icon: Icons.people_alt_rounded,
                        iconColor: const Color(0xFF10B981),
                        title: '2. قنوات التواجد (Presence Channels)',
                        badge: 'تتطلب تسجيل الدخول ⚠️',
                        badgeColor: const Color(0xFFF59E0B),
                        description:
                            'يجب تسجيل الدخول أولاً؛ لتوقيع طلب الانضمام والمصادقة على هويتك لدى السيرفر (/api/broadcasting/auth-manual). تُستخدم لرادار المتواجدين (Here, Joining, Leaving) والهمس المباشر (Whisper).',
                      ),
                      _buildChannelPillar(
                        icon: Icons.lock_outline_rounded,
                        iconColor: const Color(0xFFA855F7),
                        title: '3. القنوات الخاصة (Private Channels)',
                        badge: 'تتطلب تسجيل الدخول ⚠️',
                        badgeColor: const Color(0xFFF59E0B),
                        description:
                            'تتطلب توثيق المستخدم وتوكن معتمد (private-user.{id})؛ لاستقبال تنبيهات كسر العرض (Outbid) والأحداث الموجهة لشخصك حصراً وبأمان.',
                      ),
                      _buildChannelPillar(
                        icon: Icons.notifications_active_rounded,
                        iconColor: const Color(0xFFEC4899),
                        title: '4. تجربة الإشعارات (FCM Push)',
                        badge: 'تنبيهات فورية',
                        badgeColor: const Color(0xFF10B981),
                        description:
                            'اختبار استقبال إشعارات الـ Push في الواجهة (Foreground) والخلفية (Background) عند كسر المزايدة أو الفوز، أو إرسال إشعار تجريبي مباشر من لوحة تحكم HosteDay.',
                      ),
                    ];

                    if (isNarrow) {
                      return Column(
                        children: items
                            .map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: item,
                                ))
                            .toList(),
                      );
                    }

                    return Column(
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(child: items[0]),
                            const SizedBox(width: 10),
                            Expanded(child: items[1]),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(child: items[2]),
                            const SizedBox(width: 10),
                            Expanded(child: items[3]),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                // Call-To-Action if user is not logged in
                if (!isAuth) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFFBBF24),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'تنبيه: لتفعيل ظهورك في رادار المتواجدين واستقبال إشعارات كسر المزايدة الخاصة بك، يرجى تسجيل الدخول أولاً.',
                            style: TextStyle(
                              color: Color(0xFFFDE68A),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            minimumSize: const Size(0, 34),
                          ),
                          onPressed: () => Get.toNamed('/login'),
                          child: const Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelPillar({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badge,
    required Color badgeColor,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF10101C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

