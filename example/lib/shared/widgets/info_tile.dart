import 'package:flutter/material.dart';

/// Displays one label/value row.
class InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const InfoTile({
    required this.label,
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
