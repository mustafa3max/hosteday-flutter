import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../../../../core/models/action_feedback.dart';

class AuthFormController extends ChangeNotifier {
  AuthFormController()
    : nameController = TextEditingController(text: 'Mustafa'),
      emailController = TextEditingController(text: 'user@example.com'),
      passwordController = TextEditingController();

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  bool _isRegisterMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isDisposed = false;

  bool get isRegisterMode => _isRegisterMode;
  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;

  String get title => _isRegisterMode ? 'إنشاء حساب جديد' : 'تسجيل الدخول';

  String get description {
    return _isRegisterMode
        ? 'أنشئ حساباً وسيتم حفظ الجلسة تلقائياً.'
        : 'سجّل الدخول. لا تحتاج إلى إدخال Bearer Token يدوياً.';
  }

  void toggleRegisterMode() {
    if (_isLoading) {
      return;
    }

    _isRegisterMode = !_isRegisterMode;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    if (_isLoading) {
      return;
    }

    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<ActionFeedback> submit() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      return const ActionFeedback(
        message: 'أدخل البريد الإلكتروني وكلمة المرور.',
        isError: true,
      );
    }

    if (_isRegisterMode && name.isEmpty) {
      return const ActionFeedback(
        message: 'أدخل الاسم لإنشاء الحساب.',
        isError: true,
      );
    }

    _setLoading(true);

    try {
      final credential = _isRegisterMode
          ? await HosteDay.auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
              additionalData: <String, dynamic>{'name': name},
            )
          : await HosteDay.auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );

      final userName =
          credential.user.displayName ??
          credential.user.email ??
          credential.user.id;

      return ActionFeedback(
        message: _isRegisterMode
            ? 'تم إنشاء الحساب وتسجيل الدخول باسم $userName.'
            : 'تم تسجيل الدخول باسم $userName.',
      );
    } on HosteDayAuthException catch (error) {
      return ActionFeedback(
        message: 'فشلت المصادقة: ${error.message}',
        isError: true,
      );
    } on HosteDayException catch (error) {
      return ActionFeedback(
        message: 'فشل الطلب: ${error.message}',
        isError: true,
      );
    } catch (error) {
      return ActionFeedback(
        message: 'حدث خطأ غير متوقع: $error',
        isError: true,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<ActionFeedback> sendResetPasswordEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      return const ActionFeedback(
        message: 'أدخل البريد الإلكتروني أولاً.',
        isError: true,
      );
    }

    _setLoading(true);

    try {
      await HosteDay.auth.sendPasswordResetEmail(email: email);

      return const ActionFeedback(
        message:
            'تم إرسال تعليمات إعادة تعيين كلمة المرور إلى البريد الإلكتروني.',
      );
    } on HosteDayAuthException catch (error) {
      return ActionFeedback(
        message: 'تعذر إرسال طلب إعادة التعيين: ${error.message}',
        isError: true,
      );
    } on HosteDayException catch (error) {
      return ActionFeedback(
        message: 'فشل الطلب: ${error.message}',
        isError: true,
      );
    } catch (error) {
      return ActionFeedback(
        message: 'حدث خطأ غير متوقع: $error',
        isError: true,
      );
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;

    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
