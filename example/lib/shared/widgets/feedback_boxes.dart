import 'package:flutter/material.dart';

/// Error message displayed inside forms and pages.
class ErrorBox extends StatelessWidget {
  final String message;

  const ErrorBox({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}

/// Success message displayed after completed actions.
class SuccessBox extends StatelessWidget {
  final String message;

  const SuccessBox({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
