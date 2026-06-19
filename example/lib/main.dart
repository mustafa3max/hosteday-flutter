import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

late final HosteDayClient hosteday;

void main() {
  hosteday = HosteDayClient(
    config: const HosteDayConfig(baseUrl: 'https://enterprise.hosteday.com'),
  );

  runApp(const App());
}

class BrandColors {
  static const Color primary = Color(0xFF18181B);
  static const Color secondary = Color(0xFF27272A);
  static const Color accent = Color(0xFF34D399);
  static const Color textAccent = Color(0xFF18181B);
  static const Color textMain = Color(0xFFF4F4F5);
  static const Color textMuted = Color(0xFFA1A1AA);
  static const Color border = Color(0xFF3F3F46);
  static const Color danger = Color(0xFFFB7185);
  static const Color warning = Color(0xFFFBBF24);
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HosteDay API Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: BrandColors.primary,
        colorScheme: const ColorScheme.dark(
          primary: BrandColors.accent,
          onPrimary: BrandColors.textAccent,
          secondary: BrandColors.secondary,
          surface: BrandColors.secondary,
          onSurface: BrandColors.textMain,
          error: BrandColors.danger,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: BrandColors.primary,
          foregroundColor: BrandColors.textMain,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: BrandColors.secondary,
          labelStyle: const TextStyle(color: BrandColors.textMuted),
          hintStyle: const TextStyle(color: BrandColors.textMuted),
          prefixIconColor: BrandColors.textMuted,
          suffixIconColor: BrandColors.textMuted,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: BrandColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: BrandColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: BrandColors.accent, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: BrandColors.border),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: BrandColors.accent,
            foregroundColor: BrandColors.textAccent,
            disabledBackgroundColor: BrandColors.border,
            disabledForegroundColor: BrandColors.textMuted,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(foregroundColor: BrandColors.textMain),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: BrandColors.textMain,
            fontWeight: FontWeight.w800,
          ),
          titleLarge: TextStyle(
            color: BrandColors.textMain,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            color: BrandColors.textMain,
            fontWeight: FontWeight.w700,
          ),
          bodyMedium: TextStyle(color: BrandColors.textMuted),
          bodySmall: TextStyle(color: BrandColors.textMuted),
        ),
      ),
      home: const HosteDayApiExamplePage(),
    );
  }
}

class HosteDayApiExamplePage extends StatefulWidget {
  const HosteDayApiExamplePage({super.key});

  @override
  State<HosteDayApiExamplePage> createState() => _HosteDayApiExamplePageState();
}

class _HosteDayApiExamplePageState extends State<HosteDayApiExamplePage> {
  final TextEditingController _nameController = TextEditingController(
    text: 'Mustafa',
  );

  final TextEditingController _emailController = TextEditingController(
    text: 'user@example.com',
  );

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _bearerTokenController = TextEditingController();

  final TextEditingController _apiTokenController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  String? _statusMessage;
  String? _rawResponse;
  String? _lastExtractedToken;

  Map<String, String> _headers({
    bool withBearerToken = false,
    bool withApiToken = true,
  }) {
    final headers = <String, String>{};

    final bearerToken = _bearerTokenController.text.trim();
    final apiToken = _apiTokenController.text.trim();

    if (withBearerToken && bearerToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $bearerToken';
    }

    if (withApiToken && apiToken.isNotEmpty) {
      headers['X-Api-Token'] = apiToken;
    }

    return headers;
  }

  Future<void> _runRequest({
    required String loadingMessage,
    required String successMessage,
    required Future<Map<String, dynamic>> Function() request,
    bool extractToken = false,
  }) async {
    setState(() {
      _isLoading = true;
      _statusMessage = loadingMessage;
      _rawResponse = null;

      if (extractToken) {
        _lastExtractedToken = null;
      }
    });

    try {
      final response = await request();

      final formattedResponse = const JsonEncoder.withIndent(
        '  ',
      ).convert(response);

      final token = extractToken ? _extractToken(response) : null;

      setState(() {
        _rawResponse = formattedResponse;
        _lastExtractedToken = token;

        if (extractToken && (token == null || token.isEmpty)) {
          _statusMessage =
              '$successMessage لكن لم يتم العثور على token في الاستجابة.';
        } else {
          _statusMessage = successMessage;
        }

        if (token != null && token.isNotEmpty) {
          _bearerTokenController.text = token;
        }
      });
    } on HosteDayException catch (e) {
      setState(() {
        _statusMessage = 'فشل الطلب: ${e.message}';
        _rawResponse = const JsonEncoder.withIndent('  ').convert({
          'message': e.message,
          'statusCode': e.statusCode,
          'error': e.error,
        });
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'حدث خطأ غير متوقع: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      _showMessage('أدخل البريد الإلكتروني.');
      return;
    }

    if (password.isEmpty) {
      _showMessage('أدخل كلمة المرور.');
      return;
    }

    await _runRequest(
      loadingMessage: 'جاري تسجيل الدخول...',
      successMessage: 'تم تسجيل الدخول بنجاح.',
      extractToken: true,
      request: () {
        return hosteday.post(
          hosteday.config.loginPathPost,
          body: {'email': email, 'password': password},
          headers: _headers(withApiToken: true),
        );
      },
    );
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty) {
      _showMessage('أدخل الاسم.');
      return;
    }

    if (email.isEmpty) {
      _showMessage('أدخل البريد الإلكتروني.');
      return;
    }

    if (password.isEmpty) {
      _showMessage('أدخل كلمة المرور.');
      return;
    }

    await _runRequest(
      loadingMessage: 'جاري إنشاء الحساب...',
      successMessage: 'تم إنشاء الحساب بنجاح.',
      extractToken: true,
      request: () {
        return hosteday.post(
          hosteday.config.registerPathPost,
          body: {'name': name, 'email': email, 'password': password},
          headers: _headers(withApiToken: true),
        );
      },
    );
  }

  Future<void> _getUser() async {
    await _runRequest(
      loadingMessage: 'جاري جلب بيانات المستخدم...',
      successMessage: 'تم جلب بيانات المستخدم بنجاح.',
      request: () {
        return hosteday.get(
          hosteday.config.userShowPathGet,
          headers: _headers(withBearerToken: true, withApiToken: true),
        );
      },
    );
  }

  Future<void> _updateUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    await _runRequest(
      loadingMessage: 'جاري تحديث بيانات المستخدم...',
      successMessage: 'تم تحديث بيانات المستخدم بنجاح.',
      request: () {
        return hosteday.put(
          hosteday.config.userUpdatePathPut,
          body: {
            if (name.isNotEmpty) 'name': name,
            if (email.isNotEmpty) 'email': email,
            if (password.isNotEmpty) 'password': password,
          },
          headers: _headers(withBearerToken: true, withApiToken: true),
        );
      },
    );
  }

  Future<void> _logout() async {
    await _runRequest(
      loadingMessage: 'جاري تسجيل الخروج...',
      successMessage: 'تم تسجيل الخروج بنجاح.',
      request: () {
        return hosteday.post(
          hosteday.config.logoutPathPost,
          headers: _headers(withBearerToken: true, withApiToken: true),
        );
      },
    );
  }

  Future<void> _getPosts() async {
    await _runRequest(
      loadingMessage: 'جاري جلب المنشورات...',
      successMessage: 'تم جلب المنشورات بنجاح.',
      request: () {
        return hosteday.get(
          '/api/posts',
          headers: _headers(withBearerToken: true, withApiToken: true),
        );
      },
    );
  }

  void _showMessage(String message) {
    setState(() {
      _statusMessage = message;
    });
  }

  void _clearResult() {
    setState(() {
      _statusMessage = null;
      _rawResponse = null;
      _lastExtractedToken = null;
    });
  }

  String? _extractToken(Map<String, dynamic> response) {
    final directToken = response['token'] ?? response['access_token'];

    if (directToken != null) {
      return directToken.toString();
    }

    final data = response['data'];

    if (data is Map) {
      final nestedToken = data['token'] ?? data['access_token'];

      if (nestedToken != null) {
        return nestedToken.toString();
      }
    }

    return null;
  }

  @override
  void dispose() {
    hosteday.dispose();

    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _bearerTokenController.dispose();
    _apiTokenController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasToken =
        _lastExtractedToken != null && _lastExtractedToken!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HosteDay API Example'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _clearResult,
            icon: const Icon(Icons.refresh),
            tooltip: 'Clear result',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(color: BrandColors.primary),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _HeaderSection(baseUrl: hosteday.config.baseUrl),
                const SizedBox(height: 24),
                _CredentialsSection(
                  nameController: _nameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  bearerTokenController: _bearerTokenController,
                  apiTokenController: _apiTokenController,
                  obscurePassword: _obscurePassword,
                  isLoading: _isLoading,
                  onTogglePassword: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                const SizedBox(height: 20),
                _ActionsSection(
                  isLoading: _isLoading,
                  onLogin: _login,
                  onRegister: _register,
                  onGetUser: _getUser,
                  onUpdateUser: _updateUser,
                  onLogout: _logout,
                  onGetPosts: _getPosts,
                ),
                const SizedBox(height: 20),
                if (_statusMessage != null)
                  _StatusCard(
                    message: _statusMessage!,
                    isSuccess: hasToken || _rawResponse != null,
                  ),
                if (_lastExtractedToken != null) ...[
                  const SizedBox(height: 20),
                  _CodeBlock(
                    title: 'Extracted Token',
                    content: _lastExtractedToken!,
                  ),
                ],
                if (_rawResponse != null) ...[
                  const SizedBox(height: 20),
                  _CodeBlock(title: 'API Response', content: _rawResponse!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final String baseUrl;

  const _HeaderSection({required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        color: BrandColors.secondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: BrandColors.accent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.cloud_done_outlined,
              size: 38,
              color: BrandColors.textAccent,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'HosteDay Flutter',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'API client example',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: BrandColors.primary,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: BrandColors.border),
            ),
            child: Text(
              baseUrl,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: BrandColors.textMuted,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialsSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController bearerTokenController;
  final TextEditingController apiTokenController;

  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePassword;

  const _CredentialsSection({
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.bearerTokenController,
    required this.apiTokenController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePassword,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Request Data',
      subtitle: 'Fill in the data required for your API requests.',
      child: Column(
        children: [
          _AppTextField(
            controller: nameController,
            enabled: !isLoading,
            label: 'Name',
            hint: 'Mustafa',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          _AppTextField(
            controller: emailController,
            enabled: !isLoading,
            label: 'Email',
            hint: 'user@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            enabled: !isLoading,
            obscureText: obscurePassword,
            style: const TextStyle(color: BrandColors.textMain),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.password_outlined),
              suffixIcon: IconButton(
                onPressed: isLoading ? null : onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _AppTextField(
            controller: bearerTokenController,
            enabled: !isLoading,
            label: 'Bearer Token',
            hint: 'USER_TOKEN_HERE',
            icon: Icons.key_outlined,
            minLines: 1,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _AppTextField(
            controller: apiTokenController,
            enabled: !isLoading,
            label: 'X-Api-Token',
            hint: 'PROJECT_API_TOKEN_HERE',
            icon: Icons.security_outlined,
            minLines: 1,
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

class _ActionsSection extends StatelessWidget {
  final bool isLoading;

  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onGetUser;
  final VoidCallback onUpdateUser;
  final VoidCallback onLogout;
  final VoidCallback onGetPosts;

  const _ActionsSection({
    required this.isLoading,
    required this.onLogin,
    required this.onRegister,
    required this.onGetUser,
    required this.onUpdateUser,
    required this.onLogout,
    required this.onGetPosts,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Actions',
      subtitle: 'Test HosteDay API endpoints from one place.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLoading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: const LinearProgressIndicator(
                minHeight: 6,
                backgroundColor: BrandColors.primary,
                color: BrandColors.accent,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionButton(
                label: 'Login',
                icon: Icons.login,
                isLoading: isLoading,
                onPressed: onLogin,
              ),
              _ActionButton(
                label: 'Register',
                icon: Icons.person_add_alt,
                isLoading: isLoading,
                onPressed: onRegister,
              ),
              _ActionButton(
                label: 'Get User',
                icon: Icons.account_circle_outlined,
                isLoading: isLoading,
                onPressed: onGetUser,
              ),
              _ActionButton(
                label: 'Update User',
                icon: Icons.edit_outlined,
                isLoading: isLoading,
                onPressed: onUpdateUser,
              ),
              _ActionButton(
                label: 'Get Posts',
                icon: Icons.article_outlined,
                isLoading: isLoading,
                onPressed: onGetPosts,
              ),
              _ActionButton(
                label: 'Logout',
                icon: Icons.logout,
                isLoading: isLoading,
                onPressed: onLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: BrandColors.secondary,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String message;
  final bool isSuccess;

  const _StatusCard({required this.message, required this.isSuccess});

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? BrandColors.accent : BrandColors.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandColors.secondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.info_outline,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String title;
  final String content;

  const _CodeBlock({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      subtitle: 'The latest response returned from the API.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: BrandColors.primary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BrandColors.border),
        ),
        child: SelectableText(
          content,
          style: const TextStyle(
            color: BrandColors.textMain,
            fontFamily: 'monospace',
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int? minLines;
  final int? maxLines;

  const _AppTextField({
    required this.controller,
    required this.enabled,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.minLines,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines ?? 1,
      style: const TextStyle(color: BrandColors.textMain),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }
}
