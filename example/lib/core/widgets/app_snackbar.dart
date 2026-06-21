import 'package:flutter/material.dart';

import '../models/action_feedback.dart';

abstract final class AppSnackbar {
  static void show(BuildContext context, ActionFeedback feedback) {
    final backgroundColor =
        feedback.isError ? Colors.redAccent : Colors.tealAccent;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: backgroundColor,
          content: Text(
            feedback.message,
            style: TextStyle(
              color: feedback.isError ? Colors.white : Colors.black,
            ),
          ),
        ),
      );
  }
}
