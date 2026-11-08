import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/live_bidding_controller.dart';

/// Activity feed card displaying all events arriving via Presence, Public,
/// Private channels, and FCM Push in real-time.
class RealTimeLogsCard extends StatelessWidget {
  const RealTimeLogsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LiveBiddingController>();
    final theme = Theme.of(context);

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
                Icons.stream_rounded,
                color: Color(0xFF38BDF8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'سجل الأنشطة اللحظية (3 Channels + FCM)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Obx(() => Text(
                    '${controller.biddingLogs.length} حدث',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: Obx(() {
              final logs = controller.biddingLogs;
              if (logs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'في انتظار أول نشاط أو مزايدة...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                itemCount: logs.length,
                separatorBuilder: (context, index) => Divider(
                  color: const Color(0xFF262636).withValues(alpha: 0.6),
                  height: 12,
                ),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return _buildLogItem(context, log, controller);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(
    BuildContext context,
    Map<String, dynamic> log,
    LiveBiddingController controller,
  ) {
    final channelType = log['channel_type']?.toString() ?? 'Unknown';
    final title = log['title']?.toString() ?? '';
    final description = log['description']?.toString() ?? '';
    final amount = log['amount'] as int?;
    final timestamp = log['timestamp'] as DateTime? ?? DateTime.now();

    final badgeColor = _resolveBadgeColor(channelType);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Channel Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: badgeColor.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Text(
              channelType,
              style: TextStyle(
                color: badgeColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Event Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (amount != null)
                      Text(
                        '+$amount\$',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Time
          Text(
            controller.formatTime(timestamp),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Color _resolveBadgeColor(String channelType) {
    if (channelType.contains('Whisper')) {
      return const Color(0xFFF59E0B);
    } else if (channelType.contains('Presence')) {
      return const Color(0xFF10B981);
    } else if (channelType.contains('Private')) {
      return const Color(0xFFEF4444);
    } else if (channelType.contains('Public')) {
      return const Color(0xFF8B5CF6);
    } else if (channelType.contains('Push')) {
      return const Color(0xFF38BDF8);
    }
    return const Color(0xFF9CA3AF);
  }
}
