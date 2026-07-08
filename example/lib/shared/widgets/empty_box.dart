import 'package:flutter/material.dart';

/// Empty-state widget used when a list has no data.
class EmptyBox extends StatelessWidget {
  final String message;

  const EmptyBox({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(message),
      ),
    );
  }
}
