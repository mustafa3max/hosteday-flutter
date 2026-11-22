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
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.stream_rounded,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'live_bidding_activity_feed_title'.tr,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Obx(
                () => Text(
                  'live_bidding_events_count'.trParams({
                    'count': controller.biddingLogs.length.toString(),
                  }),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: Obx(() {
              final logs = controller.biddingLogs;
              if (logs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'live_bidding_waiting_events'.tr,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
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
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
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
    final theme = Theme.of(context);
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
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
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
