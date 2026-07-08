```dart
import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

const projectDomain = 'project.hosteday.com';

const projectApiKey = String.fromEnvironment(
  'HOSTEDAY_PROJECT_API_KEY',
  defaultValue: 'YOUR_PROJECT_API_KEY',
);

const realtimeAppKey = String.fromEnvironment(
  'HOSTEDAY_REALTIME_APP_KEY',
  defaultValue: 'YOUR_REALTIME_APP_KEY',
);

const realtimeHost = String.fromEnvironment(
  'HOSTEDAY_REALTIME_HOST',
  defaultValue: 'ws3.hosteday.com',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HosteDay.initializeApp(
    options: const <String, Object?>{
      HosteDayOptionKeys.projectDomain: projectDomain,

      // Project API key.
      //
      // This is not the authenticated user's access token.
      HosteDayOptionKeys.projectApiKey: projectApiKey,

      // Optional realtime configuration.
      //
      // This key is provided by HosteDay.
      // It does not require a Pusher account.
      HosteDayOptionKeys.realtimeAppKey: realtimeAppKey,
      HosteDayOptionKeys.realtimeHost: realtimeHost,
      HosteDayOptionKeys.realtimeScheme: 'wss',
      HosteDayOptionKeys.realtimePort: 443,
    },

    // Stores the authenticated session using shared_preferences.
    //
    // This keeps the user signed in after closing and reopening the app.
    authStorage: HosteDaySharedPreferencesAuthStorage(),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HosteDay Quick Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder<HosteDayUser?>(
        stream: HosteDay.auth.authStateChanges(),
        initialData: HosteDay.auth.currentUser,
        builder: (context, snapshot) {
          final user = snapshot.data;

          if (user == null) {
            return const AuthPage();
          }

          return HomePage(user: user);
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

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final userName = name.text.trim();
    final userEmail = email.text.trim();
    final userPassword = password.text;

    if (!isLogin && userName.isEmpty) {
      showMessage('Enter your name.');
      return;
    }

    if (userEmail.isEmpty || !userEmail.contains('@')) {
      showMessage('Enter a valid email address.');
      return;
    }

    if (userPassword.length < 8) {
      showMessage('Password must be at least 8 characters.');
      return;
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
          additionalData: <String, dynamic>{
            'name': userName,
          },
        );
      }
    } catch (error) {
      if (mounted) {
        showMessage(readableError(error));
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> sendPasswordResetEmail() async {
    final userEmail = email.text.trim();

    if (userEmail.isEmpty || !userEmail.contains('@')) {
      showMessage('Enter your email address first.');
      return;
    }

    setState(() => loading = true);

    try {
      await HosteDay.auth.sendPasswordResetEmail(
        email: userEmail,
      );

      if (mounted) {
        showMessage('Password reset email has been sent.');
      }
    } catch (error) {
      if (mounted) {
        showMessage(readableError(error));
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = isLogin ? 'Sign In' : 'Create Account';
    final buttonText = isLogin ? 'Sign In' : 'Create Account';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Icon(
                  Icons.cloud_outlined,
                  size: 72,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme
                      .of(context)
                      .textTheme
                      .headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Quickly test HosteDay authentication and session storage.',
                  textAlign: TextAlign.center,
                  style: Theme
                      .of(context)
                      .textTheme
                      .bodyMedium,
                ),
                const SizedBox(height: 28),
                if (!isLogin) ...<Widget>[
                  TextField(
                    controller: name,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Name',
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
                  autofillHints: const <String>[
                    AutofillHints.email,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: password,
                  obscureText: obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[
                    AutofillHints.password,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Password',
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
                  onSubmitted: (_) {
                    if (!loading) {
                      submit();
                    }
                  },
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : Text(buttonText),
                  ),
                ),
                const SizedBox(height: 12),
                if (isLogin)
                  TextButton(
                    onPressed: loading ? null : sendPasswordResetEmail,
                    child: const Text('Forgot password? Send reset email'),
                  ),
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
                        ? 'Don’t have an account? Create one'
                        : 'Already have an account? Sign in',
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

class HomePage extends StatefulWidget {
  const HomePage({
    required this.user,
    super.key,
  });

  final HosteDayUser user;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = false;

  Future<void> reloadUser() async {
    setState(() => loading = true);

    try {
      await HosteDay.auth.reload();

      if (mounted) {
        showMessage('User profile reloaded.');
      }
    } catch (error) {
      if (mounted) {
        showMessage(readableError(error));
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> sendVerificationEmail() async {
    setState(() => loading = true);

    try {
      await HosteDay.auth.sendEmailVerification();

      if (mounted) {
        showMessage('Verification email has been sent.');
      }
    } catch (error) {
      if (mounted) {
        showMessage(readableError(error));
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> logout() async {
    await HosteDay.auth.signOut();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HosteDayUser?>(
      stream: HosteDay.auth.userChanges(),
      initialData: widget.user,
      builder: (context, snapshot) {
        final user = snapshot.data ?? widget.user;

        final displayName = user.displayName ?? user.name ?? 'User';
        final email = user.email ?? 'No email';
        final photoUrl = user.photoUrl;

        return Scaffold(
          appBar: AppBar(
            title: const Text('HosteDay'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Sign out',
                onPressed: logout,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 42,
                      backgroundImage: photoUrl == null || photoUrl.isEmpty
                          ? null
                          : NetworkImage(photoUrl),
                      child: photoUrl == null || photoUrl.isEmpty
                          ? const Icon(Icons.person, size: 42)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome $displayName',
                      textAlign: TextAlign.center,
                      style: Theme
                          .of(context)
                          .textTheme
                          .headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    UserInfoCard(user: user),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: loading ? null : reloadUser,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reload user'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: loading ? null : sendVerificationEmail,
                      icon: const Icon(Icons.mark_email_read_outlined),
                      label: const Text('Send verification email'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: loading ? null : logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign out'),
                    ),
                    if (loading) ...<Widget>[
                      const SizedBox(height: 20),
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class UserInfoCard extends StatelessWidget {
  const UserInfoCard({
    required this.user,
    super.key,
  });

  final HosteDayUser user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: <Widget>[
          UserInfoTile(
            label: 'User ID',
            value: user.id,
          ),
          UserInfoTile(
            label: 'Name',
            value: user.displayName ?? user.name ?? '-',
          ),
          UserInfoTile(
            label: 'Email',
            value: user.email ?? '-',
          ),
          UserInfoTile(
            label: 'Email verified',
            value: user.emailVerified ? 'Yes' : 'No',
          ),
          UserInfoTile(
            label: 'Photo URL',
            value: user.photoUrl ?? '-',
          ),
        ],
      ),
    );
  }
}

class UserInfoTile extends StatelessWidget {
  const UserInfoTile({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label),
      subtitle: SelectableText(value),
    );
  }
}

String readableError(Object error) {
  if (error is HosteDayException) {
    return error.displayMessage;
  }

  return error.toString();
}
```
