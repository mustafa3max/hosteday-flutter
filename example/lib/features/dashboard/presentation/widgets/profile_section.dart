import 'package:flutter/material.dart';

import '../../../../core/widgets/section_card.dart';
import '../controllers/dashboard_controller.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.controller,
    required this.onUpdate,
  });

  final DashboardController controller;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final isLoading = controller.isBusy;

    return SectionCard(
      title: 'تحديث المستخدم',
      subtitle: 'يستخدم HosteDay.auth.updateProfile(...).',
      child: Column(
        children: <Widget>[
          TextField(
            controller: controller.nameController,
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: 'الاسم',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.emailController,
            enabled: !isLoading,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'البريد الإلكتروني',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: isLoading ? null : onUpdate,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Update Profile'),
          ),
        ],
      ),
    );
  }
}
