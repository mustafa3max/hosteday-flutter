import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../../../../core/errors/error_presenter.dart';
import '../../../../shared/widgets/example_header.dart';
import '../../../../shared/widgets/example_scaffold.dart';
import '../../../../shared/widgets/feedback_boxes.dart';
import '../../../../shared/widgets/form_fields.dart';

/// Forgot-password page.
///
/// The app only asks HosteDay to send the reset email. The actual password reset
/// is completed through the web page opened from the email link.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _loading = false;
  String? _message;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
      _errorMessage = null;
    });

    try {
      await HosteDay.auth.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      setState(() {
        _message = 'Password reset email has been sent.';
      });
    } catch (error) {
      setState(() {
        _errorMessage = ErrorPresenter.messageFrom(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExampleScaffold(
      title: 'Forgot password',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const ExampleHeader(
              title: 'Reset password',
              subtitle: 'Enter your email and HosteDay will send a reset link.',
            ),
            const SizedBox(height: 24),
            EmailField(controller: _emailController),
            const SizedBox(height: 16),
            if (_message != null) ...<Widget>[
              SuccessBox(message: _message!),
              const SizedBox(height: 12),
            ],
            if (_errorMessage != null) ...<Widget>[
              ErrorBox(message: _errorMessage!),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _loading ? null : _sendResetEmail,
              child: Text(_loading ? 'Sending...' : 'Send reset email'),
            ),
          ],
        ),
      ),
    );
  }
}
