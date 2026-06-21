import 'package:flutter/material.dart';

import '../../../../core/widgets/result_card.dart';
import '../../../../core/widgets/section_card.dart';
import '../controllers/dashboard_controller.dart';

class ProtectedApiSection extends StatelessWidget {
  const ProtectedApiSection({
    super.key,
    required this.controller,
    required this.onGetPosts,
  });

  final DashboardController controller;
  final VoidCallback onGetPosts;

  @override
  Widget build(BuildContext context) {
    final isLoading = controller.isBusy;

    return SectionCard(
      title: 'طلبات API المحمية',
      subtitle:
          'التوكن يُضاف تلقائياً بسبب withAuth: true ولا يتم إدخاله يدوياً.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          FilledButton.icon(
            onPressed: isLoading ? null : onGetPosts,
            icon: const Icon(Icons.article_outlined),
            label: const Text('Get Posts'),
          ),
          OutlinedButton.icon(
            onPressed: isLoading ? null : controller.clearApiResult,
            icon: const Icon(Icons.clear),
            label: const Text('Clear Result'),
          ),
        ],
      ),
    );
  }
}

class ApiResultSection extends StatelessWidget {
  const ApiResultSection({
    super.key,
    required this.controller,
  });

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return ResultCard(
      title: controller.apiResultIsError ? 'API Error' : 'Latest API Response',
      value: controller.apiResult!,
      isError: controller.apiResultIsError,
    );
  }
}
