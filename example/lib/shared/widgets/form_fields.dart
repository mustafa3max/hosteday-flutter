import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Email input with email icon and validation.
class EmailField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final TextInputAction textInputAction;

  const EmailField({
    required this.controller,
    this.label,
    this.hint,
    this.textInputAction = TextInputAction.next,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction,
      autofillHints: const <String>[AutofillHints.email],
      decoration: InputDecoration(
        labelText: label ?? 'email_label'.tr,
        hintText: hint ?? 'email_hint'.tr,
        prefixIcon: const Icon(Icons.email_outlined),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';

        if (text.isEmpty) {
          return 'email_required'.tr;
        }

        if (!text.contains('@') || !text.contains('.')) {
          return 'email_invalid'.tr;
        }

        return null;
      },
    );
  }
}

/// Password input with show/hide visibility toggle and validation.
class PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final TextInputAction textInputAction;
  final String? Function(String?)? customValidator;
  final ValueNotifier<bool> _obscureNotifier = ValueNotifier<bool>(true);

  PasswordField({
    required this.controller,
    this.label,
    this.hint,
    this.textInputAction = TextInputAction.done,
    this.customValidator,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _obscureNotifier,
      builder: (context, obscureText, _) {
        return TextFormField(
          controller: controller,
          obscureText: obscureText,
          textInputAction: textInputAction,
          autofillHints: const <String>[AutofillHints.password],
          decoration: InputDecoration(
            labelText: label ?? 'password_label'.tr,
            hintText: hint ?? 'password_hint'.tr,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              tooltip: obscureText ? 'show_password'.tr : 'hide_password'.tr,
              onPressed: () {
                _obscureNotifier.value = !_obscureNotifier.value;
              },
            ),
          ),
          validator: customValidator ??
              (value) {
                final text = value ?? '';

                if (text.isEmpty) {
                  return 'password_required'.tr;
                }

                if (text.length < 4) {
                  return 'password_too_short'.tr;
                }

                return null;
              },
        );
      },
    );
  }
}

/// Text input for display name or full name.
class NameField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final TextInputAction textInputAction;

  const NameField({
    required this.controller,
    this.label,
    this.hint,
    this.textInputAction = TextInputAction.next,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textInputAction: textInputAction,
      autofillHints: const <String>[AutofillHints.name],
      decoration: InputDecoration(
        labelText: label ?? 'name_label'.tr,
        hintText: hint ?? 'name_hint'.tr,
        prefixIcon: const Icon(Icons.person_outline),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) {
          return 'name_required'.tr;
        }
        if (text.length < 2) {
          return 'name_too_short'.tr;
        }
        return null;
      },
    );
  }
}

String? requiredValidator(String? value) {
  final text = value?.trim() ?? '';

  if (text.isEmpty) {
    return 'confirm_password_required'.tr;
  }

  return null;
}
