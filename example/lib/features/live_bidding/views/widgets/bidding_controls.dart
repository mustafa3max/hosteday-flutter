import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/live_bidding_controller.dart';

/// Quick action controls for placing instant bids via Presence Channel Whisper.
class BiddingControls extends StatelessWidget {
  const BiddingControls({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LiveBiddingController>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF262636),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.bolt_rounded,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'المزايدة السريعة بالهمس (Instant Whisper Bids)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
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
                return const Text(
                  'بدون حفظ في DB',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildBidButton(
                  context,
                  increment: 10,
                  label: '+10 \$',
                  gradient: const <Color>[Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  onTap: () => controller.submitBid(10),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBidButton(
                  context,
                  increment: 50,
                  label: '+50 \$',
                  gradient: const <Color>[Color(0xFF7C3AED), Color(0xFF6D28D9)],
                  onTap: () => controller.submitBid(50),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBidButton(
                  context,
                  increment: 100,
                  label: '+100 \$',
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

    return Obx(() {
      final disabled = controller.isSubmittingBid.value ||
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
                        Colors.grey.shade800,
                        Colors.grey.shade900,
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
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

