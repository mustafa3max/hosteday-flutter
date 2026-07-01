```dart
import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

const projectDomain = 'https://a-y-service.hosteday.com';

const apiToken = String.fromEnvironment(
  'HOSTEDAY_API_TOKEN',
  defaultValue: 'YOUR_API_TOKEN',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HosteDay.initializeApp(
    options: const {
      HosteDayOptionKeys.projectDomain: projectDomain,
      HosteDayOptionKeys.apiToken: apiToken,
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: StreamBuilder<HosteDayUser?>(
        stream: HosteDay.auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.data == null) {
            return const AuthPage();
          }

          return HomePage(user: snapshot.data!);
        },
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  bool isLogin = true;
  bool loading = false;
  bool obscurePassword = true;

  Future<void> submit() async {
    final userEmail = email.text.trim();
    final userPassword = password.text;

    if (userEmail.isEmpty || !userEmail.contains('@')) {
      showMessage('أدخل بريدًا إلكترونيًا صحيحًا');
      return;
    }

    if (userPassword.length < 4) {
      showMessage('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      return;
    }

    if (!isLogin) {
      if (name.text
          .trim()
          .isEmpty) {
        showMessage('أدخل الاسم');
        return;
      }
    }

    setState(() => loading = true);

    try {
      if (isLogin) {
        await HosteDay.auth.signInWithEmailAndPassword(
          email: userEmail,
          password: userPassword,
        );
      } else {
        await HosteDay.auth.createUserWithEmailAndPassword(
          email: userEmail,
          password: userPassword,
          additionalData: {'name': name.text.trim()},
        );
      }
    } catch (error) {
      if (mounted) {
        showMessage(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = isLogin ? 'تسجيل الدخول' : 'إنشاء حساب';
    final buttonText = isLogin ? 'تسجيل الدخول' : 'إنشاء الحساب';

    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.cloud_outlined, size: 72),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme
                      .of(context)
                      .textTheme
                      .headlineSmall,
                ),
                const SizedBox(height: 28),

                if (!isLogin) ...[
                  TextField(
                    controller: name,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: password,
                  obscureText: obscurePassword,
                  textInputAction: isLogin
                      ? TextInputAction.done
                      : TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                ),


                const SizedBox(height: 20),

                FilledButton(
                  onPressed: loading ? null : submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: loading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Text(buttonText),
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: loading
                      ? null
                      : () {
                    setState(() {
                      isLogin = !isLogin;
                      password.clear();
                    });
                  },
                  child: Text(
                    isLogin
                        ? 'ليس لديك حساب؟ إنشاء حساب جديد'
                        : 'لديك حساب بالفعل؟ تسجيل الدخول',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({required this.user, super.key});

  final HosteDayUser user;

  Future<void> logout() async {
    await HosteDay.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HosteDay'),
        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Center(
        child: Text(
          'مرحبًا ${user.displayName ?? user.email ?? 'User'}',
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
```
