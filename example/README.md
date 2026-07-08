# HosteDay Flutter Example

A complete Flutter example app demonstrating how to use the `hosteday_flutter` package with HosteDay
services.

This example is designed to help developers quickly understand how to initialize HosteDay,
authenticate users, persist sessions, read user data, connect to realtime services, and interact
with a custom API table.

---

## What this example includes

This example demonstrates:

* HosteDay SDK initialization.
* Persistent auth session storage using `shared_preferences`.
* Email/password sign in.
* Email/password registration.
* Password reset email request.
* Auth state handling.
* Current user display.
* User profile reload.
* Email verification request.
* Sign out.
* Realtime connection setup.
* Custom API usage with a `posts` table.

---

## Project structure

```txt
example/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── bootstrap/
│   │   │   └── hosteday_initializer.dart
│   │   ├── config/
│   │   │   └── example_environment.dart
│   │   └── theme/
│   │       └── example_theme.dart
│   ├── features/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── posts/
│   │   ├── profile/
│   │   └── realtime/
│   └── shared/
│       └── widgets/
├── pubspec.yaml
└── README.md
```

---

## Required HosteDay values

Before running the example, you need your HosteDay project values:

```txt
HOSTEDAY_PROJECT_DOMAIN
HOSTEDAY_PROJECT_API_KEY
HOSTEDAY_REALTIME_APP_KEY
HOSTEDAY_REALTIME_HOST
```

Example:

```txt
HOSTEDAY_PROJECT_DOMAIN=a-y-service.hosteday.com
HOSTEDAY_PROJECT_API_KEY=your_project_api_key
HOSTEDAY_REALTIME_APP_KEY=your_realtime_app_key
HOSTEDAY_REALTIME_HOST=a-y-service.hosteday.com
```

The project API key is not the user access token.

The user access token is created after sign in and is managed automatically by HosteDay Auth.

---

## Running the example

From the package root:

```bash
cd example
flutter pub get
flutter run \
  --dart-define=HOSTEDAY_PROJECT_DOMAIN=a-y-service.hosteday.com \
  --dart-define=HOSTEDAY_PROJECT_API_KEY=your_project_api_key \
  --dart-define=HOSTEDAY_REALTIME_APP_KEY=your_realtime_app_key \
  --dart-define=HOSTEDAY_REALTIME_HOST=a-y-service.hosteday.com
```

If Android, iOS, Web, Linux, macOS, or Windows folders do not exist yet, generate them once:

```bash
flutter create .
```

Then run again:

```bash
flutter run
```

---

## SDK initialization

HosteDay is initialized before running the Flutter app.

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HosteDayInitializer.initialize();

  runApp(const HosteDayExampleApp());
}
```

The initializer keeps all HosteDay configuration in one place:

```dart
await
HosteDay.initializeApp
(
options: <String, Object?>{
HosteDayOptionKeys.projectDomain: ExampleEnvironment.projectDomain,
HosteDayOptionKeys.projectApiKey: ExampleEnvironment.projectApiKey,
HosteDayOptionKeys.realtimeAppKey: ExampleEnvironment.realtimeAppKey,
HosteDayOptionKeys.realtimeHost: ExampleEnvironment.realtimeHost,
HosteDayOptionKeys.realtimeScheme: ExampleEnvironment.realtimeScheme,
HosteDayOptionKeys.realtimePort: ExampleEnvironment.realtimePort,
},
authStorage: HosteDaySharedPreferencesAuthStorage(),
connectRealtime: false,
);
```

---

## Environment configuration

The example reads configuration from `--dart-define`.

```dart

static const String projectDomain = String.fromEnvironment(
  'HOSTEDAY_PROJECT_DOMAIN',
  defaultValue: 'project.hosteday.com',
);
```

The first argument must be the environment variable name, not the actual domain.

Correct:

```dart
String.fromEnvironment
('HOSTEDAY_PROJECT_DOMAIN
'
,defaultValue:
'
a-y-service.hosteday.com
'
,
);
```

Incorrect:

```dart
String.fromEnvironment
('https://a-y-service.hosteday.com
'
,defaultValue:
'
https://project.hosteday.com
'
,
);
```

---

## Authentication

### Sign in

```dart
await
HosteDay.auth.signInWithEmailAndPassword
(
email
:
email
,
password
:
password
,
);
```

### Register

```dart
await
HosteDay.auth.createUserWithEmailAndPassword
(
email: email,
password: password,
additionalData: <String, dynamic>{
'name': name,
},
);
```

### Forgot password

```dart
await
HosteDay.auth.sendPasswordResetEmail
(
email
:
email
,
);
```

The Flutter app only requests the password reset email.

The actual password reset is completed through the web link sent to the user.

---

## Auth state

The example uses `authStateChanges()` to decide whether to show the auth pages or the authenticated
home page.

```dart
StreamBuilder<HosteDayUser?>
(
stream: HosteDay.auth.authStateChanges(),
initialData: HosteDay.auth.currentUser,
builder: (context, snapshot) {
final user = snapshot.data;

if (user == null) {
return const SignInPage();
}

return HomeShell(user: user);
},
);
```

---

## Persistent session storage

The example uses:

```dart
HosteDaySharedPreferencesAuthStorage
()
```

This stores the authenticated session locally using `shared_preferences`.

This means the user stays signed in after closing and reopening the app.

---

## User profile

The example demonstrates:

```dart
HosteDay.auth.currentUser;HosteDay.auth.userChanges
();

await
HosteDay.auth.reload
();

await
HosteDay.auth.updateProfile
(<String, dynamic>{
'name': name,
},
);

await HosteDay.auth.sendEmailVerification();
```

Email verification is completed through the web link sent by email.

The Flutter app only requests sending the verification email.

---

## Sign out

```dart
await
HosteDay.auth.signOut
();
```

After signing out, the stored session is cleared and the app returns to the auth screen.

---

## Custom API example: posts

The example includes a custom table named `posts`.

Expected endpoints:

```http
GET /api/posts
POST /api/posts
```

Load posts:

```dart

final response = await
HosteDay.client.get
('/api/posts
'
,withAuth:
true
,
);
```

Create post:

```dart

final response = await
HosteDay.client.post
('/api/posts
'
,withAuth: true,
body: <String, dynamic>{
'title': title,
'body': body,
},
);
```

A simple list response can be:

```json
{
  "data": [
    {
      "id": 1,
      "title": "First post",
      "body": "This is an example post.",
      "created_at": "2026-07-08 10:00:00"
    }
  ]
}
```

---

## Realtime

The example connects to HosteDay realtime manually:

```dart
await
HosteDay.connectRealtime
();
```

Listening to a public channel:

```dart
await
HosteDay.realtime.listenPublic
(
channel: 'posts',
event: 'PostCreated',
onEvent: (event) {
final payload = event.payload;
},
);
```

The realtime app key is provided by HosteDay.

It does not require a Pusher account.

HosteDay uses a Pusher-compatible realtime protocol internally.

---

## Expected realtime event

The Posts page listens to:

```txt
channel: posts
event: PostCreated
```

Expected payload:

```json
{
  "post": {
    "id": 2,
    "title": "New post",
    "body": "Created from another client."
  }
}
```

If the event payload does not include readable post data, the example reloads the posts list from
`/api/posts`.

---

## Troubleshooting

### `HosteDay request error`

This usually means one of the following:

* The project domain is incorrect.
* The project API key is missing or invalid.
* The backend returned a non-JSON response.
* The API endpoint is not available.
* The app is using old environment variable names.

Make sure you use:

```bash
--dart-define=HOSTEDAY_PROJECT_DOMAIN=a-y-service.hosteday.com
--dart-define=HOSTEDAY_PROJECT_API_KEY=your_project_api_key
```

Do not use the old name:

```bash
HOSTEDAY_PROJECT_ACCESS_TOKEN
```

---

### `Missing authentication token`

This means the request requires a signed-in user.

Make sure the user is signed in before calling:

```dart
withAuth: true
```

---

### Realtime does not connect

Check these values:

```bash
--dart-define=HOSTEDAY_REALTIME_APP_KEY=your_realtime_app_key
--dart-define=HOSTEDAY_REALTIME_HOST=a-y-service.hosteday.com
```

Also make sure the realtime app key is not the same as the project API key.

---

## Notes

This example is intentionally educational.

It separates app concerns into clear sections:

* `core` for configuration, initialization, theme, and utilities.
* `features` for auth, posts, profile, realtime, and home.
* `shared` for reusable widgets.

For a very quick test, see `EXAMPLE.md` and the Quick Experience section.
