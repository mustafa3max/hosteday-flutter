import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../../../../core/utils/realtime_utils.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../controllers/dashboard_controller.dart';

class RealtimeSection extends StatelessWidget {
  const RealtimeSection({
    super.key,
    required this.controller,
    required this.onConnect,
    required this.onSubscribe,
    required this.onPublish,
    required this.onUnsubscribe,
    required this.onDisconnect,
  });

  final DashboardController controller;
  final VoidCallback onConnect;
  final VoidCallback onSubscribe;
  final VoidCallback onPublish;
  final VoidCallback onUnsubscribe;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final isLoading = controller.isBusy;

    return SectionCard(
      title: 'Realtime',
      subtitle:
          'القنوات الخاصة وPresence تستخدم جلسة HosteDayAuth الحالية تلقائياً.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              StatusChip(
                label: controller.isRealtimeConnected
                    ? 'Connected'
                    : 'Disconnected',
                active: controller.isRealtimeConnected,
              ),
              StatusChip(
                label: controller.isRealtimeSubscribed
                    ? 'Subscribed'
                    : 'Not subscribed',
                active: controller.isRealtimeSubscribed,
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<HosteDayChannelType>(
            initialValue: controller.channelType,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'نوع القناة',
              prefixIcon: Icon(Icons.hub_outlined),
            ),
            items: HosteDayChannelType.values
                .map(
                  (type) => DropdownMenuItem<HosteDayChannelType>(
                    value: type,
                    child: Text(RealtimeUtils.channelTypeLabel(type)),
                  ),
                )
                .toList(),
            onChanged: isLoading ? null : controller.changeChannelType,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.channelController,
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: 'Channel',
              hintText: 'tenant.chat.room.1',
              prefixIcon: Icon(Icons.forum_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.eventController,
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: 'Event',
              hintText: 'message.sent',
              prefixIcon: Icon(Icons.bolt_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.payloadController,
            enabled: !isLoading,
            minLines: 5,
            maxLines: 10,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: const InputDecoration(
              labelText: 'Payload JSON',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 80),
                child: Icon(Icons.data_object_outlined),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: isLoading ? null : onConnect,
                icon: const Icon(Icons.power_settings_new),
                label: const Text('Connect'),
              ),
              FilledButton.icon(
                onPressed: isLoading ? null : onSubscribe,
                icon: const Icon(Icons.add_link),
                label: const Text('Subscribe'),
              ),
              FilledButton.icon(
                onPressed: isLoading ? null : onPublish,
                icon: const Icon(Icons.send_outlined),
                label: const Text('Send Event'),
              ),
              OutlinedButton.icon(
                onPressed: isLoading ? null : onUnsubscribe,
                icon: const Icon(Icons.link_off_outlined),
                label: const Text('Unsubscribe'),
              ),
              OutlinedButton.icon(
                onPressed: isLoading ? null : onDisconnect,
                icon: const Icon(Icons.power_off_outlined),
                label: const Text('Disconnect'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
