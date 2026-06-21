import 'package:flutter/material.dart';

import '../../../../core/widgets/app_snackbar.dart';
import '../controllers/auth_form_controller.dart';

class HosteDayAuthPage extends StatefulWidget {
  const HosteDayAuthPage({super.key});

  @override
  State<HosteDayAuthPage> createState() => _HosteDayAuthPageState();
}

class _HosteDayAuthPageState extends State<HosteDayAuthPage> {
  late final AuthFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AuthFormController();
  }

  Future<void> _submit() async {
    final feedback = await _controller.submit();

    if (!mounted) {
      return;
    }

    AppSnackbar.show(context, feedback);
  }

  Future<void> _sendResetPasswordEmail() async {
    final feedback = await _controller.sendResetPasswordEmail();

    if (!mounted) {
      return;
    }

    AppSnackbar.show(context, feedback);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isLoading = _controller.isLoading;

        return Scaffold(
          appBar: AppBar(title: const Text('HosteDay Authentication')),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Icon(
                          Icons.cloud_done_outlined,
                          size: 62,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _controller.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _controller.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        if (_controller.isRegisterMode) ...<Widget>[
                          TextField(
                            controller: _controller.nameController,
                            enabled: !isLoading,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'الاسم',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextField(
                          controller: _controller.emailController,
                          enabled: !isLoading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            hintText: 'user@example.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _controller.passwordController,
                          enabled: !isLoading,
                          obscureText: _controller.obscurePassword,
                          onSubmitted: (_) => isLoading ? null : _submit(),
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: isLoading
                                  ? null
                                  : _controller.togglePasswordVisibility,
                              icon: Icon(
                                _controller.obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: isLoading ? null : _submit,
                          icon: isLoading
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _controller.isRegisterMode
                                      ? Icons.person_add_alt
                                      : Icons.login,
                                ),
                          label: Text(
                            isLoading
                                ? 'جاري التنفيذ...'
                                : _controller.isRegisterMode
                                ? 'إنشاء الحساب'
                                : 'تسجيل الدخول',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : _controller.toggleRegisterMode,
                          child: Text(
                            _controller.isRegisterMode
                                ? 'لدي حساب بالفعل'
                                : 'إنشاء حساب جديد',
                          ),
                        ),
                        if (!_controller.isRegisterMode)
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : _sendResetPasswordEmail,
                            child: const Text('نسيت كلمة المرور؟'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
