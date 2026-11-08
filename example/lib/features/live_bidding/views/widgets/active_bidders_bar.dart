import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/live_bidding_controller.dart';
import '../../models/bidder_model.dart';

/// Horizontal radar bar visualizing all active members currently subscribed
/// to the Presence Channel (`presence-auction.room`).
class ActiveBiddersBar extends StatelessWidget {
  const ActiveBiddersBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LiveBiddingController>();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              // Pulsing green radar radar icon
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Color(0x6610B981),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'رادار المتواجدين (Presence Radar)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              Obx(() {
                final count = controller.onlineBidders.length;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '$count متصل الآن',
                    style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 74,
            child: Obx(() {
              final bidders = controller.onlineBidders;
              if (bidders.isEmpty) {
                return Center(
                  child: Text(
                    'جاري مسح المتواجدين في الغرفة...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                );
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: bidders.length,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final bidder = bidders[index];
                  return _buildBidderAvatar(context, bidder, controller);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBidderAvatar(
    BuildContext context,
    BidderModel bidder,
    LiveBiddingController controller,
  ) {
    final isLeader = bidder.id == controller.highestBidderId.value;
    final isSelf = bidder.id == controller.currentUserId;
    final hasAvatar =
        bidder.avatarUrl != null && bidder.avatarUrl!.trim().isNotEmpty;

    return Tooltip(
      message:
          '${bidder.name}\nالمعرف: ${bidder.id}\nوقت الانضمام: ${controller.formatTime(bidder.joinedAt)}',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showBidderDetailsSheet(context, bidder, controller),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isLeader
                          ? const LinearGradient(
                              colors: <Color>[
                                Color(0xFFF59E0B),
                                Color(0xFFEF4444),
                              ],
                            )
                          : (isSelf
                              ? const LinearGradient(
                                  colors: <Color>[
                                    Color(0xFF06B6D4),
                                    Color(0xFF3B82F6),
                                  ],
                                )
                              : const LinearGradient(
                                  colors: <Color>[
                                    Color(0xFF4F46E5),
                                    Color(0xFF9333EA),
                                  ],
                                )),
                      border: Border.all(
                        color: isLeader
                            ? const Color(0xFFFBBF24)
                            : (isSelf
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFF6366F1)),
                        width: isLeader ? 2.2 : 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: hasAvatar
                          ? Image.network(
                              bidder.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildLetterAvatar(bidder),
                            )
                          : _buildLetterAvatar(bidder),
                    ),
                  ),
                  // Online Green Indicator
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF13131A),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  if (isLeader)
                    const Positioned(
                      top: -7,
                      right: -4,
                      child: Text(
                        '👑',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 68,
                child: Text(
                  isSelf ? 'أنت' : bidder.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelf ? FontWeight.bold : FontWeight.w500,
                    color: isSelf
                        ? const Color(0xFF38BDF8)
                        : Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLetterAvatar(BidderModel bidder) {
    final initial = bidder.name.trim().isNotEmpty
        ? bidder.name.trim()[0].toUpperCase()
        : '?';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  void _showBidderDetailsSheet(
    BuildContext context,
    BidderModel bidder,
    LiveBiddingController controller,
  ) {
    final isLeader = bidder.id == controller.highestBidderId.value;
    final isSelf = bidder.id == controller.currentUserId;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF161624),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isLeader
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF3B82F6),
                    child: Text(
                      bidder.name.isNotEmpty
                          ? bidder.name.trim()[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          bidder.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'المعرف (ID): ${bidder.id}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isLeader)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Text(
                        '👑 متصدر المزاد',
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const Divider(color: Color(0xFF262636), height: 28),
              _buildDetailRow(
                Icons.radar_rounded,
                'قناة التواجد',
                'presence-${LiveBiddingController.presenceChannelName}',
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                Icons.access_time_rounded,
                'وقت الانضمام للرادار',
                controller.formatTime(bidder.joinedAt),
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                Icons.verified_user_rounded,
                'حالة العضو',
                isSelf ? 'أنت (الجلسة الحالية)' : 'مزايد نشط في الغرفة (Here)',
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: const Color(0xFF818CF8)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
