import 'package:flutter/material.dart';

/// A reusable wrapper for simple full-screen pages such as auth pages.
class ExampleScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const ExampleScaffold({
    required this.title,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[child],
            ),
          ),
        ),
      ),
    );
  }
}
