import 'package:flutter/material.dart';

import '../../../../core/widgets/section_card.dart';
import '../controllers/dashboard_controller.dart';

class CurrentSessionSection extends StatelessWidget {
  const CurrentSessionSection({
    super.key,
    required this.controller,
    required this.onReloadUser,
    required this.onVerifyEmail,
  });

  final DashboardController controller;
  final VoidCallback onReloadUser;
  final VoidCallback onVerifyEmail;

  @override
  Widget build(BuildContext context) {
    final user = controller.user;
    final isLoading = controller.isBusy;
    final identity = user.displayName ?? user.email ?? user.id;
    final initial = identity.isEmpty
        ? '?'
        : identity.substring(0, 1).toUpperCase();

    return SectionCard(
      title: 'الجلسة الحالية',
      subtitle: 'تتم إدارة التوكن والجلسة داخلياً بواسطة HosteDayAuth.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text(initial)),
            title: Text(user.displayName ?? 'بدون اسم'),
            subtitle: Text(user.email ?? user.id),
            trailing: user.emailVerified
                ? const Icon(Icons.verified_outlined, color: Colors.tealAccent)
                : const Icon(Icons.warning_amber_outlined, color: Colors.amber),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: isLoading ? null : onReloadUser,
                icon: const Icon(Icons.refresh),
                label: const Text('Reload User'),
              ),
              OutlinedButton.icon(
                onPressed: isLoading ? null : onVerifyEmail,
                icon: const Icon(Icons.mark_email_read_outlined),
                label: const Text('Verify Email'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
