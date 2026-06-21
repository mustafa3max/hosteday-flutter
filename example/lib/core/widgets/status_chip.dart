import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.active,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.tealAccent : Colors.grey;

    return Chip(
      avatar: Icon(
        active ? Icons.check_circle_outline : Icons.circle_outlined,
        size: 18,
        color: color,
      ),
      label: Text(label),
      side: BorderSide(color: color),
    );
  }
}
