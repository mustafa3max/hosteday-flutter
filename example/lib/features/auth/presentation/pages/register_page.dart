import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';
import 'package:hosteday_flutter_example/features/posts/presentation/pages/home_page.dart';

import '../../../../core/errors/error_presenter.dart';
import '../../../../shared/widgets/example_header.dart';
import '../../../../shared/widgets/example_scaffold.dart';
import '../../../../shared/widgets/feedback_boxes.dart';
import '../../../../shared/widgets/form_fields.dart';

/// Registration page.
///
/// The backend may send a verification email after registration depending on
/// the project configuration.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
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
      await HosteDay.auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        additionalData: <String, dynamic>{'name': _nameController.text.trim()},
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

  @override
  Widget build(BuildContext context) {
    return ExampleScaffold(
      title: 'Create account',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const ExampleHeader(
              title: 'Create an account',
              subtitle: 'Create a user and continue to the home page.',
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              enabled: !_loading,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: requiredValidator,
            ),
            const SizedBox(height: 12),
            EmailField(controller: _emailController),
            const SizedBox(height: 12),
            PasswordField(controller: _passwordController),
            const SizedBox(height: 16),
            if (_errorMessage != null) ...<Widget>[
              ErrorBox(message: _errorMessage!),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _loading ? null : _register,
              child: Text(_loading ? 'Creating...' : 'Create account'),
            ),
          ],
        ),
      ),
    );
  }
}
