import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';
import 'package:hosteday_flutter_example/features/posts/presentation/pages/home_page.dart';

import '../../../../core/errors/error_presenter.dart';
import '../../../../shared/widgets/example_header.dart';
import '../../../../shared/widgets/example_scaffold.dart';
import '../../../../shared/widgets/feedback_boxes.dart';
import '../../../../shared/widgets/form_fields.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

/// Email/password sign-in page.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _loading) {
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await HosteDay.auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomePage()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

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

  void _openRegisterPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const RegisterPage()));
  }

  void _openForgotPasswordPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ForgotPasswordPage()));
  }

  @override
  Widget build(BuildContext context) {
    return ExampleScaffold(
      title: 'Sign in',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const ExampleHeader(
              title: 'Welcome to HosteDay',
              subtitle: 'Sign in to test auth, profile, posts, and realtime.',
            ),
            const SizedBox(height: 24),
            EmailField(controller: _emailController),
            const SizedBox(height: 12),
            PasswordField(controller: _passwordController),
            const SizedBox(height: 16),
            if (_errorMessage != null) ...<Widget>[
              ErrorBox(message: _errorMessage!),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _loading ? null : _signIn,
              child: Text(_loading ? 'Signing in...' : 'Sign in'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loading ? null : _openForgotPasswordPage,
              child: const Text('Forgot password?'),
            ),
            TextButton(
              onPressed: _loading ? null : _openRegisterPage,
              child: const Text('Create new account'),
            ),
          ],
        ),
      ),
    );
  }
}
