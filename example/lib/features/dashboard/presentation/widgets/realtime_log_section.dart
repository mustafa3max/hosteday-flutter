import 'package:flutter/material.dart';

import '../../../../core/widgets/section_card.dart';
import '../../data/models/realtime_log.dart';
import '../controllers/dashboard_controller.dart';

class RealtimeLogSection extends StatelessWidget {
  const RealtimeLogSection({
    super.key,
    required this.controller,
  });

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final logs = controller.realtimeLogs;

    return SectionCard(
      title: 'Realtime Log',
      subtitle: 'أحدث عمليات الاتصال والاشتراك والأحداث المستلمة.',
      child: logs.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('لا توجد أحداث Realtime بعد.'),
              ),
            )
          : Column(
              children: logs
                  .map(
                    (log) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RealtimeLogCard(log: log),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class RealtimeLogCard extends StatelessWidget {
  const RealtimeLogCard({
    super.key,
    required this.log,
  });

  final RealtimeLog log;

  @override
  Widget build(BuildContext context) {
    final color = log.isError ? Colors.redAccent : Colors.lightBlueAccent;
    final time =
        '${log.createdAt.hour.toString().padLeft(2, '0')}:'
        '${log.createdAt.minute.toString().padLeft(2, '0')}:'
        '${log.createdAt.second.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: log.isError ? color : Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                log.isError ? Icons.error_outline : Icons.sensors_outlined,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  log.title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ),
              Text(time, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            log.details,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
