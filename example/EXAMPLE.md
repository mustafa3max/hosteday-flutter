# HosteDay Flutter Complete Example

This example is a small but complete Flutter app that demonstrates how to use
`hosteday_flutter` in a clean educational structure.

## Quick Experience Example

If you only want to test HosteDay quickly without exploring the full structured
example, start here:

[Open the Quick Experience example](#quick-experience-example)

The Quick Experience is a single-file Flutter example designed to test the
platform quickly. It includes SDK initialization, persistent session storage,
sign in, registration, password reset email requests, user data display,
profile updates, avatar upload, email verification requests, user reload, and
sign out.

---

## Features covered

The example demonstrates:

- Email/password sign in.
- Email/password registration.
- Forgot-password email flow.
- Auth state handling through an `AuthGate`.
- Persistent authentication using `shared_preferences`.
- Current user profile display.
- User profile update.
- User avatar selection and upload.
- Full HTTPS avatar URL display.
- Email verification request.
- Custom API table usage with `/api/posts`.
- Creating posts with authenticated requests.
- Listening to realtime `PostCreated` events.
- Sign out and session clearing.

---

## Project structure

```txt
example/
├── pubspec.yaml
├── analysis_options.yaml
├── EXAMPLE.md
└── lib/
    ├── main.dart
    ├── app.dart
    ├── core/
    │   ├── bootstrap/
    │   │   └── hosteday_initializer.dart
    │   ├── config/
    │   │   └── example_environment.dart
    │   ├── errors/
    │   │   └── error_presenter.dart
    │   ├── theme/
    │   │   └── example_theme.dart
    │   └── utils/
    │       └── api_response_reader.dart
    ├── features/
    │   ├── auth/
    │   │   └── presentation/
    │   │       ├── auth_gate.dart
    │   │       └── pages/
    │   │           ├── forgot_password_page.dart
    │   │           ├── register_page.dart
    │   │           └── sign_in_page.dart
    │   ├── home/
    │   │   └── presentation/
    │   │       └── home_shell.dart
    │   ├── posts/
    │   │   ├── data/
    │   │   │   ├── post_api_paths.dart
    │   │   │   ├── post_realtime_service.dart
    │   │   │   └── post_repository.dart
    │   │   ├── models/
    │   │   │   └── post.dart
    │   │   └── presentation/
    │   │       ├── pages/
    │   │       │   └── posts_page.dart
    │   │       └── widgets/
    │   │           ├── create_post_form.dart
    │   │           └── post_card.dart
    │   ├── profile/
    │   │   └── presentation/
    │   │       └── pages/
    │   │           └── profile_page.dart
    │   └── realtime/
    │       └── presentation/
    │           └── pages/
    │               └── realtime_page.dart
    └── shared/
        └── widgets/
            ├── empty_box.dart
            ├── example_header.dart
            ├── example_scaffold.dart
            ├── feedback_boxes.dart
            ├── form_fields.dart
            └── info_tile.dart
```

---

## Required dependencies

The example uses `shared_preferences` for persistent sessions and
`image_picker` for selecting profile images.

Add the following dependencies to `example/pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  hosteday_flutter:
    path: ../

  shared_preferences: ^2.5.3
  image_picker: ^1.1.2
```

Then run:

```bash
cd example
flutter pub get
```

---

## File responsibilities

### `lib/main.dart`

A small entry point that initializes Flutter bindings, initializes HosteDay,
then runs the example app.

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HosteDayInitializer.initialize();

  runApp(const HosteDayExampleApp());
}
```

### `lib/app.dart`

Defines `HosteDayExampleApp`, the root `MaterialApp`, the theme, and the first
screen: `AuthGate`.

### `lib/core/bootstrap/hosteday_initializer.dart`

Keeps SDK initialization in one place. This makes it easy to replace the example
configuration with production values later.

```dart
await
HosteDay.initializeApp
(
options: <String, Object?>{
HosteDayOptionKeys.projectDomain:
ExampleEnvironment.projectDomain,
HosteDayOptionKeys.projectApiKey:
ExampleEnvironment.projectApiKey,
HosteDayOptionKeys.realtimeAppKey:
ExampleEnvironment.realtimeAppKey,
HosteDayOptionKeys.realtimeHost:
ExampleEnvironment.realtimeHost,
HosteDayOptionKeys.realtimeScheme:
ExampleEnvironment.realtimeScheme,
HosteDayOptionKeys.realtimePort:
ExampleEnvironment.realtimePort,
},
authStorage: HosteDaySharedPreferencesAuthStorage(),
connectRealtime: false,
);
```

### `lib/core/config/example_environment.dart`

Contains compile-time configuration read from `--dart-define`:

- `HOSTEDAY_PROJECT_DOMAIN`
- `HOSTEDAY_PROJECT_API_KEY`
- `HOSTEDAY_REALTIME_APP_KEY`
- `HOSTEDAY_REALTIME_HOST`
- `HOSTEDAY_REALTIME_SCHEME`
- `HOSTEDAY_REALTIME_PORT`

Example:

```dart
abstract final class ExampleEnvironment {
  static const String projectDomain = String.fromEnvironment(
    'HOSTEDAY_PROJECT_DOMAIN',
    defaultValue: 'project.hosteday.com',
  );

  static const String projectApiKey = String.fromEnvironment(
    'HOSTEDAY_PROJECT_API_KEY',
  );

  static const String realtimeAppKey = String.fromEnvironment(
    'HOSTEDAY_REALTIME_APP_KEY',
  );

  static const String realtimeHost = String.fromEnvironment(
    'HOSTEDAY_REALTIME_HOST',
    defaultValue: 'project.hosteday.com',
  );

  static const String realtimeScheme = String.fromEnvironment(
    'HOSTEDAY_REALTIME_SCHEME',
    defaultValue: 'wss',
  );

  static const int realtimePort = int.fromEnvironment(
    'HOSTEDAY_REALTIME_PORT',
    defaultValue: 443,
  );
}
```

The first argument of `String.fromEnvironment` must be the environment variable
name, not the actual project URL.

Correct:

```dart

static const String projectDomain = String.fromEnvironment(
  'HOSTEDAY_PROJECT_DOMAIN',
  defaultValue: 'a-y-service.hosteday.com',
);
```

Incorrect:

```dart

static const String projectDomain = String.fromEnvironment(
  'https://a-y-service.hosteday.com',
  defaultValue: 'https://project.hosteday.com',
);
```

### `lib/features/auth/presentation/auth_gate.dart`

Listens to `HosteDay.auth.authStateChanges()` and decides whether the app should
show `SignInPage` or `HomeShell`.

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

### `lib/features/auth/presentation/pages/sign_in_page.dart`

Demonstrates:

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

### `lib/features/auth/presentation/pages/register_page.dart`

Demonstrates:

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

### `lib/features/auth/presentation/pages/forgot_password_page.dart`

Demonstrates:

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

The actual password reset is completed through the web flow opened from the
email link.

### `lib/features/home/presentation/home_shell.dart`

Authenticated app shell containing the bottom navigation tabs:

- Posts
- User
- Realtime

It also includes the sign-out action:

```dart
await
HosteDay.auth.signOut
();
```

### `lib/features/profile/presentation/pages/profile_page.dart`

Demonstrates reading, reloading, and updating the current user.

```dart

final currentUser = HosteDay.auth.currentUser;

final userChanges = HosteDay.auth.userChanges();

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

It also demonstrates avatar selection and upload:

```dart

final picker = ImagePicker();

final image = await
picker.pickImage
(
source: ImageSource.gallery,
imageQuality: 85,
maxWidth: 1600,
maxHeight: 1600,
);

if (image != null) {
final bytes = await image.readAsBytes();

final extension = image.name
    .split('.')
    .last
    .trim()
    .toLowerCase();

await HosteDay.auth.updateAvatar(
bytes: bytes,
extension: extension,
);
}
```

Supported avatar extensions:

```txt
jpg
jpeg
png
webp
```

The SDK sends a request equivalent to:

```json
{
  "bytes": "BASE64_ENCODED_IMAGE_BYTES",
  "extension": "png"
}
```

The backend may store only a relative path:

```txt
users/USER_ID/IMAGE.png
```

The API should return a complete HTTPS URL:

```json
{
  "avatar": "https://project.hosteday.com/users/USER_ID/IMAGE.png"
}
```

The Flutter user model exposes this through:

```dart

final user = HosteDay.auth.currentUser;

final photoUrl = user?.photoUrl;
final avatarUrl = user?.avatarUrl;
```

`avatarUrl` is an alias for `photoUrl`.

Displaying the avatar:

```dart

final avatarUrl = user.avatarUrl;

CircleAvatar
(
radius: 48,
backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
? NetworkImage(avatarUrl)
    : null,
child: avatarUrl == null || avatarUrl.isEmpty
? const Icon(Icons.person)
    : null,
);
```

Using `userChanges()` allows the interface to refresh automatically after the
avatar is updated:

```dart
StreamBuilder<HosteDayUser?>
(
stream: HosteDay.auth.userChanges(),
initialData: HosteDay.auth.currentUser,
builder: (context, snapshot) {
final user = snapshot.data;
final avatarUrl = user?.avatarUrl;

return CircleAvatar(
radius: 48,
backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
? NetworkImage(avatarUrl)
    : null,
child: avatarUrl == null || avatarUrl.isEmpty
? const Icon(Icons.person)
    : null,
);
},
);
```

### `lib/features/posts/data/post_repository.dart`

Contains HTTP requests for a custom backend table named `posts`.

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

Create a post:

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

The UI does not call HTTP directly. This keeps the example easier to understand
and closer to a real app structure.

### `lib/features/posts/data/post_realtime_service.dart`

Connects to realtime and listens for post events:

```dart
await
HosteDay.connectRealtime
();

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

### `lib/features/posts/presentation/pages/posts_page.dart`

Combines the repository and realtime service:

- Loads posts when the page starts.
- Refreshes posts with pull-to-refresh.
- Creates new posts.
- Updates the list when a realtime event arrives.

### `lib/shared/widgets/*`

Reusable UI widgets used throughout the example:

- `ExampleScaffold`
- `ExampleHeader`
- `EmailField`
- `PasswordField`
- `ErrorBox`
- `SuccessBox`
- `InfoTile`
- `EmptyBox`

---

## Image picker platform configuration

### Android

Add camera permission to:

```txt
example/android/app/src/main/AndroidManifest.xml
```

Place it inside the `<manifest>` element:

```xml

<uses-permission android:name="android.permission.CAMERA" />
```

Selecting an image from the gallery normally does not require legacy storage
permissions when using current Android versions and `image_picker`.

### iOS

Add the following entries to:

```txt
example/ios/Runner/Info.plist
```

```xml

<key>NSPhotoLibraryUsageDescription</key><string>Select a profile picture.</string>

<key>NSCameraUsageDescription</key><string>Take a profile picture.</string>
```

### Web

Gallery selection is supported through the browser file picker.

Camera behavior depends on browser support and permissions. The example should
prefer gallery selection where direct camera capture is unavailable.

---

## Backend requirements

The example expects the following endpoints to exist in the HosteDay project
backend.

### Authentication

These depend on your SDK and backend configuration:

- Sign in.
- Register.
- Forgot password.
- Current user.
- Update user profile.
- Update user avatar.
- Send email verification.
- Sign out.

The avatar endpoint expects:

```http
POST /api/user/avatar
```

Request body:

```json
{
  "bytes": "BASE64_ENCODED_IMAGE_BYTES",
  "extension": "png"
}
```

A successful user response should include a complete HTTPS avatar URL:

```json
{
  "data": {
    "id": "USER_ID",
    "name": "Example User",
    "email": "user@example.com",
    "avatar": "https://project.hosteday.com/users/USER_ID/IMAGE.png"
  }
}
```

### Posts table

The custom table example expects:

```http
GET /api/posts
POST /api/posts
```

A simple successful list response:

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

A simple successful create response:

```json
{
  "data": {
    "id": 2,
    "title": "New post",
    "body": "Created from Flutter.",
    "created_at": "2026-07-08 10:05:00"
  }
}
```

The example also supports this nested response:

```json
{
  "data": {
    "post": {
      "id": 2,
      "title": "New post"
    }
  }
}
```

### Realtime event

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

A nested payload is also supported:

```json
{
  "data": {
    "post": {
      "id": 2,
      "title": "New post"
    }
  }
}
```

If the event payload does not include a readable post, the app reloads the posts
list from `/api/posts`.

---

## Running the example

From the package root:

```bash
cd example

flutter pub get

flutter run \
  --dart-define=HOSTEDAY_PROJECT_DOMAIN=your-project.hosteday.com \
  --dart-define=HOSTEDAY_PROJECT_API_KEY=your_project_api_key \
  --dart-define=HOSTEDAY_REALTIME_APP_KEY=your_realtime_app_key \
  --dart-define=HOSTEDAY_REALTIME_HOST=your-project.hosteday.com
```

Do not include `https://` in `HOSTEDAY_PROJECT_DOMAIN` unless your SDK
configuration explicitly expects a complete URL.

The project API key is not the authenticated user access token.

If Android, iOS, Web, Linux, macOS, or Windows folders do not exist yet, run
this once inside `example/`:

```bash
flutter create .
```

Then run:

```bash
flutter run
```

---

## Troubleshooting

### `HosteDay request error`

This usually means one of the following:

- The project domain is incorrect.
- The project API key is missing or invalid.
- The backend returned a non-JSON response.
- The API endpoint is unavailable.
- The app uses old environment variable names.

Use:

```bash
--dart-define=HOSTEDAY_PROJECT_DOMAIN=your-project.hosteday.com
--dart-define=HOSTEDAY_PROJECT_API_KEY=your_project_api_key
```

Do not use the old variable:

```bash
HOSTEDAY_PROJECT_ACCESS_TOKEN
```

### `Missing authentication token`

The request requires a signed-in user.

Ensure the user is authenticated before calling:

```dart
withAuth: true
```

### Avatar upload fails

Check the following:

- The user is authenticated.
- The selected image is not empty.
- The extension is one of `jpg`, `jpeg`, `png`, or `webp`.
- The backend accepts the `bytes` and `extension` fields.
- The backend request size limit is large enough.
- The backend storage folder is writable.
- The API returns the updated user or supports reloading the current user.

### Avatar URL uses HTTP

The backend should return avatar URLs using HTTPS.

For a Laravel backend, configure:

```env
APP_URL=https://project.hosteday.com
```

The database can continue storing only the relative path:

```txt
users/USER_ID/IMAGE.png
```

The API resource should return:

```txt
https://project.hosteday.com/users/USER_ID/IMAGE.png
```

### Avatar does not refresh

The `updateAvatar()` implementation should update or reload the authenticated
user after a successful upload.

Use:

```dart
HosteDay.auth.userChanges
()
```

to rebuild widgets when the current user changes.

### Realtime does not connect

Check:

```bash
--dart-define=HOSTEDAY_REALTIME_APP_KEY=your_realtime_app_key
--dart-define=HOSTEDAY_REALTIME_HOST=your-project.hosteday.com
```

The realtime app key is not the same as the project API key.

---

## Why this structure is educational

This example separates concerns clearly:

- `core` contains SDK initialization, configuration, theme, and utilities.
- `features` contains real app sections.
- `data` contains API and realtime access.
- `models` contains plain Dart models.
- `presentation` contains screens and widgets.
- `shared` contains reusable UI pieces.

This gives new users a complete example that remains easy to read, test, and
modify.