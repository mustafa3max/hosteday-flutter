import 'package:flutter/material.dart';

/// Email input with basic validation.
class EmailField extends StatelessWidget {
  final TextEditingController controller;

  const EmailField({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const <String>[AutofillHints.email],
      decoration: const InputDecoration(labelText: 'Email'),
      validator: (value) {
        final text = value?.trim() ?? '';

        if (text.isEmpty) {
          return 'Email is required.';
        }

        if (!text.contains('@')) {
          return 'Enter a valid email.';
        }

        return null;
      },
    );
  }
}

/// Password input with basic validation.
class PasswordField extends StatelessWidget {
  final TextEditingController controller;

  const PasswordField({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      textInputAction: TextInputAction.done,
      autofillHints: const <String>[AutofillHints.password],
      decoration: const InputDecoration(labelText: 'Password'),
      validator: (value) {
        final text = value ?? '';

        if (text.isEmpty) {
          return 'Password is required.';
        }

        if (text.length < 4) {
          return 'Password must be at least 4 characters.';
        }

        return null;
      },
    );
  }
}

String? requiredValidator(String? value) {
  final text = value?.trim() ?? '';

  if (text.isEmpty) {
    return 'This field is required.';
  }

  return null;
}
