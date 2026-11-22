import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/live_bidding_controller.dart';

/// Quick action controls for placing instant bids via Presence Channel Whisper.
class BiddingControls extends StatelessWidget {
  const BiddingControls({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LiveBiddingController>();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFFF59E0B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'live_bidding_instant_whisper'.tr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Obx(() {
                if (controller.isSubmittingBid.value) {
                  return const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFF59E0B),
                    ),
                  );
                }
                if (!controller.isConnected.value) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'live_bidding_ws_connecting'.tr,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'live_bidding_no_db_persistence'.tr,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildBidButton(
                  context,
                  increment: 10,
                  label: 'live_bidding_bid_increment'.trParams({
                    'amount': '10',
                  }),
                  gradient: const <Color>[Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  onTap: () => controller.submitBid(10),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBidButton(
                  context,
                  increment: 50,
                  label: 'live_bidding_bid_increment'.trParams({
                    'amount': '50',
                  }),
                  gradient: const <Color>[Color(0xFF7C3AED), Color(0xFF6D28D9)],
                  onTap: () => controller.submitBid(50),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBidButton(
                  context,
                  increment: 100,
                  label: 'live_bidding_bid_increment'.trParams({
                    'amount': '100',
                  }),
                  gradient: const <Color>[Color(0xFFD97706), Color(0xFFB45309)],
                  onTap: () => controller.submitBid(100),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBidButton(
    BuildContext context, {
    required int increment,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    final controller = Get.find<LiveBiddingController>();
    final theme = Theme.of(context);

    return Obx(() {
      final isConnected = controller.isConnected.value;
      final disabled =
          !isConnected ||
          controller.isSubmittingBid.value ||
          controller.auctionStatus.value == 'ended';

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: disabled
                  ? LinearGradient(
                      colors: <Color>[
                        theme.colorScheme.onSurface.withValues(alpha: 0.12),
                        theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      ],
                    )
                  : LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
              boxShadow: disabled
                  ? null
                  : <BoxShadow>[
                      BoxShadow(
                        color: gradient.first.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (!isConnected) ...<Widget>[
                        Icon(
                          Icons.lock_clock_rounded,
                          size: 15,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          color: disabled
                              ? theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                )
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
