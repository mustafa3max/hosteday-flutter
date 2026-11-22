import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/live_bidding_controller.dart';
import 'widgets/active_bidders_bar.dart';
import 'widgets/bidding_controls.dart';
import 'widgets/real_time_logs_card.dart';

/// Full interactive screen for the "Live Bidding Radar" feature,
/// matching the official Hosteday design language, theme system, and translations.
class LiveBiddingScreen extends GetView<LiveBiddingController> {
  const LiveBiddingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!Get.isRegistered<LiveBiddingController>()) {
      Get.put(LiveBiddingController());
    }
    final canPop = Navigator.of(context).canPop();

    final body = LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        final isTablet = constraints.maxWidth >= 600 && !isDesktop;
        final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 20.0 : 16.0);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 20,
              ),
              children: <Widget>[
                // 1. Hero Header Card
                _buildHeroHeader(context, theme),
                const SizedBox(height: 20),

                // 2. Active Bidders Presence Radar Bar
                const ActiveBiddersBar(),
                const SizedBox(height: 16),

                // 3. Outbid Alert Banner (Reactive)
                _buildOutbidAlertBanner(context, theme),

                // 4. Main Auction Arena Card
                _buildAuctionArenaCard(context, theme),
                const SizedBox(height: 16),

                // 5. Bidding Controls
                const BiddingControls(),
                const SizedBox(height: 16),

                // 6. Real-Time Activity Feed
                const RealTimeLogsCard(),
                const SizedBox(height: 20),

                // 7. Technical Lab & Channels Explanation
                _buildIntroExplanationCard(context, theme),
              ],
            ),
          ),
        );
      },
    );

    return Title(
      title: '${'live_bidding_app_bar_title'.tr} | Hosteday',
      color: theme.colorScheme.primary,
      child: canPop
          ? Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: AppBar(title: Text('live_bidding_app_bar_title'.tr)),
              body: body,
            )
          : Material(color: Colors.transparent, child: body),
    );
  }

  Widget _buildHeroHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.25 : 0.04,
            ),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.radar_rounded,
                  size: 26,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'live_bidding_hero_title'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'live_bidding_hero_desc'.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              // WebSocket Connection Status Pill
              Obx(() {
                final isConnected = controller.isConnected.value;
                final isConnecting = controller.isConnecting.value;
                final statusColor = isConnected
                    ? const Color(0xFF10B981)
                    : (isConnecting
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFEF4444));
                final statusText = isConnected
                    ? 'live_bidding_ws_connected'.tr
                    : (isConnecting
                          ? 'live_bidding_ws_connecting'.tr
                          : 'live_bidding_ws_disconnected'.tr);

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Auction Item Room Tag
              Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.gavel_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        controller.auctionTitle.value,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Identity Badge
              Builder(
                builder: (context) {
                  final isAuth = controller.isAuthenticated;
                  final statusColor = isAuth
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.35),
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
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAuth
                              ? 'live_bidding_logged_in_badge'.trParams({
                                  'name': controller.currentUserName,
                                })
                              : 'live_bidding_guest_badge'.tr,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutbidAlertBanner(BuildContext context, ThemeData theme) {
    return Obx(() {
      if (!controller.hasOutbidNotice.value) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'live_bidding_outbid_alert_title'.tr,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.lastOutbidMessage.value,
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed:
                  (!controller.isConnected.value ||
                      controller.isSubmittingBid.value)
                  ? null
                  : () => controller.submitBid(50),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                disabledBackgroundColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.12,
                ),
                disabledForegroundColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.38,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              child: Text(
                'live_bidding_regain_lead'.tr,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAuctionArenaCard(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.25 : 0.04,
            ),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          // Top Row: Status Pill and Countdown Timer
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.flash_on_rounded,
                      color: theme.colorScheme.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'live_bidding_silent_whisper_badge'.tr,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
                        'live_bidding_ends_in'.trParams({'time': time}),
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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
                      'live_bidding_highest_bid_label'.tr,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.65,
                        ),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\$$amount',
                      style: TextStyle(
                        color: isPulsing
                            ? const Color(0xFF10B981)
                            : theme.colorScheme.primary,
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
            final hasBids = controller.highestBidderId.value.isNotEmpty;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelf
                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                    : (hasBids
                          ? theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5)
                          : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.25)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelf
                      ? const Color(0xFF10B981).withValues(alpha: 0.4)
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    isSelf
                        ? 'live_bidding_you_are_leading'.tr
                        : (hasBids
                              ? 'live_bidding_current_leader'.trParams({
                                  'name': leaderName.isEmpty
                                      ? 'live_bidding_anonymous_bidder'.tr
                                      : leaderName,
                                })
                              : 'live_bidding_be_first_bidder'.tr),
                    style: TextStyle(
                      color: isSelf
                          ? const Color(0xFF10B981)
                          : (hasBids
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  )),
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

  Widget _buildIntroExplanationCard(BuildContext context, ThemeData theme) {
    final isAuth = controller.isAuthenticated;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.25 : 0.04,
            ),
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(19),
              ),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.35,
                  ),
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.cell_tower_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'live_bidding_lab_title'.tr,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'live_bidding_lab_subtitle'.tr,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.65,
                          ),
                          fontSize: 11.5,
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
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'live_bidding_intro_desc'.tr,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Channels Pillars
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 680;
                    final items = <Widget>[
                      _buildChannelPillar(
                        context,
                        icon: Icons.public_rounded,
                        iconColor: const Color(0xFF3B82F6),
                        title: 'live_bidding_ch_public_title'.tr,
                        badge: 'live_bidding_ch_public_badge'.tr,
                        badgeColor: const Color(0xFF3B82F6),
                        description: 'live_bidding_ch_public_desc'.tr,
                      ),
                      _buildChannelPillar(
                        context,
                        icon: Icons.people_alt_rounded,
                        iconColor: const Color(0xFF10B981),
                        title: 'live_bidding_ch_presence_title'.tr,
                        badge: 'live_bidding_ch_presence_badge'.tr,
                        badgeColor: const Color(0xFFF59E0B),
                        description: 'live_bidding_ch_presence_desc'.tr,
                      ),
                      _buildChannelPillar(
                        context,
                        icon: Icons.lock_outline_rounded,
                        iconColor: const Color(0xFFA855F7),
                        title: 'live_bidding_ch_private_title'.tr,
                        badge: 'live_bidding_ch_private_badge'.tr,
                        badgeColor: const Color(0xFFF59E0B),
                        description: 'live_bidding_ch_private_desc'.tr,
                      ),
                      _buildChannelPillar(
                        context,
                        icon: Icons.notifications_active_rounded,
                        iconColor: const Color(0xFFEC4899),
                        title: 'live_bidding_ch_fcm_title'.tr,
                        badge: 'live_bidding_ch_fcm_badge'.tr,
                        badgeColor: const Color(0xFF10B981),
                        description: 'live_bidding_ch_fcm_desc'.tr,
                      ),
                    ];

                    if (isNarrow) {
                      return Column(
                        children: items
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: item,
                              ),
                            )
                            .toList(),
                      );
                    }

                    return Column(
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(child: items[0]),
                            const SizedBox(width: 12),
                            Expanded(child: items[1]),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(child: items[2]),
                            const SizedBox(width: 12),
                            Expanded(child: items[3]),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                // Call-To-Action if user is not logged in
                if (!isAuth) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'live_bidding_signin_prompt'.tr,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.85,
                              ),
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
                            minimumSize: const Size(0, 36),
                          ),
                          onPressed: () => Get.toNamed('/login'),
                          child: Text(
                            'sign_in'.tr,
                            style: const TextStyle(
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

  Widget _buildChannelPillar(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badge,
    required Color badgeColor,
    required String description,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
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
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
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
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
