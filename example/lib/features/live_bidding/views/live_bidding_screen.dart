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
                const SizedBox(height: 16),

                // 1b. Connection / Auth Error Banner (if any)
                _buildConnectionErrorBanner(context, theme),

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
                  Icons.gavel_rounded,
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
              // Compact Connection Status Icon Badge with Tooltip
              Obx(() {
                final isConnected = controller.isConnected.value;
                final isConnecting = controller.isConnecting.value;
                final statusColor = isConnected
                    ? const Color(0xFF10B981)
                    : (isConnecting
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFEF4444));
                final tooltipText = isConnected
                    ? 'live_bidding_ws_connected'.tr
                    : (isConnecting
                          ? 'live_bidding_ws_connecting'.tr
                          : 'live_bidding_ws_disconnected'.tr);

                return Tooltip(
                  message: tooltipText,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                      boxShadow: isConnected
                          ? <BoxShadow>[
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.35),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      isConnected
                          ? Icons.wifi_tethering_rounded
                          : (isConnecting
                                ? Icons.sync_rounded
                                : Icons.wifi_tethering_off_rounded),
                      color: statusColor,
                      size: 16,
                    ),
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

  Widget _buildConnectionErrorBanner(BuildContext context, ThemeData theme) {
    return Obx(() {
      final err = controller.connectionError.value;
      if (err.isEmpty) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.wifi_off_rounded,
              color: theme.colorScheme.error,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SelectableText(
                err,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: controller.reconnect,
              icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.error),
              tooltip: 'retry'.tr,
            ),
          ],
        ),
      );
    });
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
          // Auction Selector Dropdown (All Active Auctions)
          Obx(() {
            final auctionsList = controller.auctions;
            final selected = controller.activeAuction.value;
            if (auctionsList.isEmpty) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.45,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selected?.id,
                    isExpanded: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    dropdownColor: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    items: auctionsList.map((auction) {
                      return DropdownMenuItem<int>(
                        value: auction.id,
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.gavel_rounded,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                auction.title,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '\$${auction.currentPrice}',
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (selectedId) {
                      if (selectedId == null) return;
                      final target = auctionsList.firstWhereOrNull(
                        (a) => a.id == selectedId,
                      );
                      if (target != null) {
                        controller.selectAuction(target);
                      }
                    },
                  ),
                ),
              ),
            );
          }),

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
                      Icons.local_fire_department_rounded,
                      color: theme.colorScheme.primary,
                      size: 15,
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
              // Countdown Timer or Continuous Open Badge
              Obx(() {
                final seconds = controller.remainingSeconds.value;
                if (seconds <= 0) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.all_inclusive_rounded,
                          color: Color(0xFF10B981),
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'مفتوح للمزايدة المستمرة',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final time = controller.formatCountdown(seconds);
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
}
