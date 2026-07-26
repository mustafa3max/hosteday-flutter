# HosteDay Flutter

[![pub package](https://img.shields.io/pub/v/hosteday_flutter.svg)](https://pub.dev/packages/hosteday_flutter)
[![platform](https://img.shields.io/badge/platform-Flutter-blue.svg)](https://flutter.dev)
[![license](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A Flutter SDK for connecting applications to HosteDay authentication, custom
APIs, persistent sessions, user management, avatar uploads, and realtime
services.

`hosteday_flutter` provides a high-level API for:

- Initializing a HosteDay project.
- Signing users in and out.
- Creating user accounts.
- Persisting authenticated sessions.
- Sending password-reset and email-verification requests.
- Reading and updating the current user.
- Uploading the current user's avatar.
- Calling public and protected custom APIs.
- Listing, showing, creating, updating, and deleting resources.
- Connecting to public, private, presence, and encrypted realtime channels.
- Publishing realtime events through HosteDay.

![Flutter Example App](https://raw.githubusercontent.com/mustafa3max/hosteday-flutter/master/assets/flutter-example.png)

---

## HosteDay platform

HosteDay is a backend and API platform that gives each project an isolated
runtime, database, generated API, HTTPS domain, authentication endpoints, file
storage, and optional realtime services.

A typical workflow is:

1. Create a project from the HosteDay dashboard.
2. Define tables such as `posts`, `orders`, or `products`.
3. Generate and configure the project API.
4. Copy the project domain.
5. Copy the project API key only when project-level API protection is enabled.
6. Copy the realtime values when realtime is required.
7. Initialize `hosteday_flutter` before calling `runApp`.

The project API key and the signed-in user's access token are different
credentials:

| Credential        | Purpose                                     | Header                      |
|-------------------|---------------------------------------------|-----------------------------|
| Project API key   | Identifies or protects the HosteDay project | `X-Api-Token` by default    |
| User access token | Authenticates the signed-in user            | `Authorization: Bearer ...` |

Do not use one credential in place of the other.

---

## Installation

Add the package to a Flutter application:

```bash
flutter pub add hosteday_flutter
```

Import the public library:

```dart
import 'package:hosteday_flutter/hosteday_flutter.dart';
```

For avatar selection from a gallery or camera, add `image_picker` to the
application:

```bash
flutter pub add image_picker
```

The SDK accepts image bytes and does not force applications to use a specific
file picker.

### Local package development

An example application inside the package repository can depend on the package
through a local path:

```yaml
dependencies:
  flutter:
    sdk: flutter

  hosteday_flutter:
    path: ../
```

Run dependency resolution from the example directory, not by pasting YAML into
the terminal:

```bash
cd example
flutter pub get
```

If recent local package changes do not appear, run:

```bash
flutter clean
flutter pub get
flutter run
```

---

## Quick start

Initialize HosteDay before running the Flutter application:

```dart
import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HosteDay.initializeApp(
    options: const <String, Object?>{
      HosteDayOptionKeys.projectDomain:
      'your-project.hosteday.com',
    },
    authStorage: HosteDaySharedPreferencesAuthStorage(),
  );

  runApp(const App());
}
```

When project-level API protection is enabled, also provide the project API key:

```dart
await
HosteDay.initializeApp
(
options: const <String, Object?>{
HosteDayOptionKeys.projectDomain:
'your-project.hosteday.com',
HosteDayOptionKeys.projectApiKey:
'YOUR_PROJECT_API_KEY',
},
authStorage
:
HosteDaySharedPreferencesAuthStorage
(
)
,
);
```

Do not configure a placeholder such as `YOUR_PROJECT_ACCESS_TOKEN` in a real
application. Omit `projectApiKey` when project protection is disabled.

---

## Configuration options

`HosteDayOptionKeys` contains only values that an application developer is
allowed to provide during SDK initialization.

Authentication and user API paths are owned by HosteDay and are not
configurable initialization options.

### Connection options

| Option                              | Description                                                              |
|-------------------------------------|--------------------------------------------------------------------------|
| `HosteDayOptionKeys.projectDomain`  | HosteDay project domain, for example `enterprise.hosteday.com`.          |
| `HosteDayOptionKeys.apiBaseUrl`     | Optional complete API base URL. Usually derived from the project domain. |
| `HosteDayOptionKeys.baseUrl`        | Alias for `apiBaseUrl`.                                                  |
| `HosteDayOptionKeys.projectApiKey`  | Optional project API key. Null or empty values are not sent.             |
| `HosteDayOptionKeys.apiTokenHeader` | Optional project key header name. Default: `X-Api-Token`.                |
| `HosteDayOptionKeys.legacyApiToken` | Legacy key kept for backward compatibility.                              |

### Realtime options

| Option                                    | Description                                                                 |
|-------------------------------------------|-----------------------------------------------------------------------------|
| `HosteDayOptionKeys.realtimeAppKey`       | Pusher-compatible application key found after `/app/` in the WebSocket URL. |
| `HosteDayOptionKeys.realtimeHost`         | Realtime WebSocket host, for example `ws3.hosteday.com`.                    |
| `HosteDayOptionKeys.realtimeScheme`       | `ws` or `wss`. Default: `wss`.                                              |
| `HosteDayOptionKeys.realtimePort`         | Realtime port. Usually `443` with `wss`.                                    |
| `HosteDayOptionKeys.broadcastingAuthPath` | Private and presence channel authorization endpoint.                        |
| `HosteDayOptionKeys.publicEventsPath`     | Public realtime event publishing endpoint.                                  |
| `HosteDayOptionKeys.privateEventsPath`    | Private realtime event publishing endpoint.                                 |
| `HosteDayOptionKeys.presenceEventsPath`   | Presence realtime event publishing endpoint.                                |

Request values such as `search`, `id`, `relationField`, and `relationValue` are
not initialization configuration. They are passed directly to request methods.
The SDK writes their backend names into the URL automatically.

For example, application code uses:

```dart
await
HosteDay.client.get
('/services
'
,search: 'booking',
relationField: 'company_id',
relationValue
:
15
,
);
```

The SDK builds a URL equivalent to:

```text
https://your-project.hosteday.com/api/services?search=booking&relation_field=company_id&relation_value=15
```

The application developer does not need to type `relation_field` or
`relation_value` manually.

---

## Initialization with realtime

```dart
await
HosteDay.initializeApp
(
options: const <String, Object?>{
HosteDayOptionKeys.projectDomain:
'your-project.hosteday.com',
HosteDayOptionKeys.realtimeAppKey:
'YOUR_REALTIME_APP_KEY',
HosteDayOptionKeys.realtimeHost:
'ws3.hosteday.com',
HosteDayOptionKeys.realtimeScheme: 'wss',
HosteDayOptionKeys.realtimePort: 443,
},
authStorage
:
HosteDaySharedPreferencesAuthStorage
(
)
,
);
```

Connect when realtime is needed:

```dart
await
HosteDay.connectRealtime
();
```

To connect immediately during initialization:

```dart
await
HosteDay.initializeApp
(
options: const <String, Object?>{
HosteDayOptionKeys.projectDomain:
'your-project.hosteday.com',
HosteDayOptionKeys.realtimeAppKey:
'YOUR_REALTIME_APP_KEY',
HosteDayOptionKeys.realtimeHost:
'ws3.hosteday.com',
},
authStorage: HosteDaySharedPreferencesAuthStorage(),
connectRealtime: true,
);
```

---

## Environment variables

Compile-time environment variables are useful for examples and local
development:

```dart
abstract final class AppEnvironment {
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
    defaultValue: 'ws3.hosteday.com',
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

Run the application:

```bash
flutter run \
  --dart-define=HOSTEDAY_PROJECT_DOMAIN=your-project.hosteday.com \
  --dart-define=HOSTEDAY_PROJECT_API_KEY=your_project_api_key \
  --dart-define=HOSTEDAY_REALTIME_APP_KEY=your_realtime_app_key \
  --dart-define=HOSTEDAY_REALTIME_HOST=ws3.hosteday.com
```

The first argument of `String.fromEnvironment` is the environment variable
name, not the domain itself.

---

## Public SDK architecture

Use `HosteDay` and `HosteDayClient` as the public API:

```dart
HosteDay.client;HosteDay.auth;HosteDay.config;HosteDay.realtime;HosteDay.isInitialized;
```

`HosteDayClient` is the high-level facade. It owns and coordinates:

- Authentication.
- The effective user token provider.
- HTTP requests.
- Realtime connections.
- Realtime publishing helpers.
- Resource cleanup.

`HosteDayHttpClient` is a low-level implementation detail used internally by
`HosteDayClient`. Applications should not instantiate it, import it directly,
or export it from the package's main public barrel file.

The public barrel should expose the high-level API and public models, for
example:

```dart
export 'src/auth/hosteday_auth.dart';
export 'src/auth/hosteday_auth_storage.dart';
export 'src/auth/hosteday_shared_preferences_auth_storage.dart';
export 'src/auth/hosteday_token_provider.dart';
export 'src/auth/hosteday_user.dart';
export 'src/config/hosteday_config.dart';
export 'src/config/hosteday_option_keys.dart';
export 'src/exceptions/hosteday_exception.dart';
export 'src/hosteday.dart';
export 'src/hosteday_client.dart';
export 'src/realtime/hosteday_channel_type.dart';
export 'src/realtime/hosteday_realtime_client.dart';
export 'src/realtime/hosteday_realtime_event.dart';
```

Do not include this internal export:

```dart
// Internal implementation; do not export publicly.
// export 'src/http/hosteday_http_client.dart';
```

Keeping the low-level client internal prevents duplicate public APIs and lets
the package change request internals without breaking application code.

---

# Authentication

## Authentication state gate

Use `authStateChanges()` to switch between signed-in and signed-out screens:

```dart
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HosteDayUser?>(
      stream: HosteDay.auth.authStateChanges(),
      initialData: HosteDay.auth.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (user == null) {
          return const SignInPage();
        }

        return const HomePage();
      },
    );
  }
}
```

Do not use `HosteDay.auth.currentUser!.hasEmail` to decide whether a user is
authenticated. `currentUser` can be null while the session is loading. Check
whether the user object is null and react to the authentication stream.

## Sign in with email and password

```dart
try {
final credential =
await HosteDay.auth.signInWithEmailAndPassword(
email: 'user@example.com',
password: 'password123',
);

final user = credential.user;

print(user.id);
print(user.email);
} on HosteDayException catch (error) {
print(error.displayMessage);
}
```

After successful sign in, HosteDay automatically:

- Saves the session.
- Saves the user access token.
- Updates `currentUser`.
- Emits an authentication-state change.
- Uses the token when `withAuth: true` is requested.
- Uses the token to authorize private and presence channels.

Do not print the access token or complete request headers in production logs.

### Navigate to the home page after sign in

```dart
Future<void> signIn(BuildContext context) async {
  await HosteDay.auth.signInWithEmailAndPassword(
    email: emailController.text.trim(),
    password: passwordController.text,
  );

  if (!context.mounted) {
    return;
  }

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (_) => const HomePage(),
    ),
        (route) => false,
  );
}
```

## Register a new user

```dart
try {
final credential =
await HosteDay.auth.createUserWithEmailAndPassword(
email: 'new-user@example.com',
password: 'password123',
additionalData: <String, dynamic>{
'name': 'Mustafa',
},
);

print(credential.user.id);
print(credential.user.displayName);
} on HosteDayException catch (error) {
print(error.displayMessage);
}
```

Additional registration values belong inside `additionalData`:

```dart
await
HosteDay.auth.createUserWithEmailAndPassword
(
email: 'new-user@example.com',
password: 'password123',
additionalData: <String, dynamic>{
'name': 'Mustafa',
'phone': '+9647700000000',
},
);
```

After a successful registration that creates an authenticated session, an
application can navigate to `HomePage` with the same `pushAndRemoveUntil`
pattern used after sign in.

## Current user

```dart

final user = HosteDay.auth.currentUser;

if (
user == null) {
print('No user is signed in.');
} else {
print(user.id);
print(user.displayName);
print(user.email);
print(user.emailVerified);
print(user.photoUrl);
print(user.avatarUrl);
}
```

`avatarUrl` is an alias for `photoUrl`.

## Listen to user changes

```dart

final subscription = HosteDay.auth.userChanges().listen((user) {
  if (user == null) {
    print('User signed out.');
    return;
  }

  print('Current user: ${user.email}');
  print('Avatar: ${user.avatarUrl}');
});
```

Cancel the subscription when it is no longer needed:

```dart
await
subscription.cancel
();
```

## Reload the user

Use `reload()` after a profile update, email verification, or whenever fresh
server data is required:

```dart
try {
final user = await HosteDay.auth.reload();

print(user.displayName);
print(user.emailVerified);
print(user.avatarUrl);
} on HosteDayException catch (error) {
print(error.displayMessage);
}
```

## Update the user profile

```dart
try {
final user = await HosteDay.auth.updateProfile(
name: 'Mustafa Max',
);

print(user.displayName);
} on HosteDayException catch (error) {
print(error.displayMessage);
}
```

## Upload a user avatar

`updateAvatar()` accepts raw image bytes and one of these extensions:

```text
jpg
jpeg
png
webp
```

Example using `image_picker`:

```dart
import 'package:hosteday_flutter/hosteday_flutter.dart';
import 'package:image_picker/image_picker.dart';

final ImagePicker imagePicker = ImagePicker();

Future<HosteDayUser?> selectAndUploadAvatar() async {
  final image = await imagePicker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
    maxWidth: 1600,
    maxHeight: 1600,
  );

  if (image == null) {
    return null;
  }

  final bytes = await image.readAsBytes();

  if (bytes.isEmpty) {
    throw StateError('The selected image is empty.');
  }

  final dotIndex = image.name.lastIndexOf('.');

  if (dotIndex == -1 || dotIndex == image.name.length - 1) {
    throw const FormatException(
      'The selected image has no valid extension.',
    );
  }

  final extension = image.name
      .substring(dotIndex + 1)
      .trim()
      .toLowerCase();

  return HosteDay.auth.updateAvatar(
    bytes: bytes,
    extension: extension,
  );
}
```

The SDK converts the bytes to Base64. Do not add a prefix such as
`data:image/png;base64,` yourself.

The backend may store a relative path:

```text
users/USER_ID/IMAGE.png
```

The API resource should return a complete HTTPS URL:

```json
{
  "avatar": "https://project.hosteday.com/users/USER_ID/IMAGE.png"
}
```

Display the avatar:

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

### Platform configuration

For Android camera access, add this inside the `<manifest>` element in
`android/app/src/main/AndroidManifest.xml`:

```xml

<uses-permission android:name="android.permission.CAMERA" />
```

For iOS, add these entries to `ios/Runner/Info.plist`:

```xml

<key>NSPhotoLibraryUsageDescription</key><string>Select a profile picture.</string>

<key>NSCameraUsageDescription</key><string>Take a profile picture.</string>
```

Web gallery selection uses the browser file picker. Camera capture depends on
browser capabilities and user permission.

## Send email verification

```dart
await
HosteDay.auth.sendEmailVerification
();
```

Verification is completed through the web link sent to the user.

## Send a password-reset email

```dart
await
HosteDay.auth.sendPasswordResetEmail
(
email
    :
'
user@example.com
'
,
);
```

Password reset is completed through the web link sent to the user.

## Delete user account

The authenticated user can permanently delete their account with:

```dart
await
HosteDay.auth.deleteUser
();
```

`deleteUser()` sends an authenticated request to the fixed HosteDay endpoint:

```http
DELETE /api/user
Authorization: Bearer USER_ACCESS_TOKEN
```

The user ID does not need to be passed manually. HosteDay identifies the current user from the
authenticated access token.

After successful account deletion, the SDK automatically:

* Clears the persisted authentication session.
* Removes the stored access token.
* Sets `currentUser` and `currentSession` to `null`.
* Emits `null` through `authStateChanges()`, `idTokenChanges()`, and `userChanges()`.
* Disconnects authenticated realtime connections.

Account deletion is permanent. Request explicit confirmation before calling `deleteUser()`:

```dart

final confirmed = await
showDialog<bool>
(
context: context,
builder: (dialogContext) {
return AlertDialog(
title: const Text('Delete account'),
content: const Text(
'Are you sure you want to permanently delete your account? '
'This action cannot be undone.',
),
actions: <Widget>[
TextButton(
onPressed: () {
Navigator.of(dialogContext).pop(false);
},
child: const Text('Cancel'),
),
FilledButton(
onPressed: () {
Navigator.of(dialogContext).pop(true);
},
child: const Text('Delete account'),
),
],
);
},
);

if (confirmed == true) {
await HosteDay.auth.deleteUser();
}
```

Do not call `signOut()` after successful deletion. The SDK has already cleared the local session
and published the signed-out authentication state.

---

## Sign out

```dart
await
HosteDay.auth.signOut
();
```

Signing out clears the local session, emits `null` through authentication
streams, and disconnects realtime. The local session is cleared even when the
remote sign-out request fails.

---

# Session storage

## Persistent storage

Use shared-preferences storage for normal applications:

```dart
await
HosteDay.initializeApp
(
options: const <String, Object?>{
HosteDayOptionKeys.projectDomain:
'your-project.hosteday.com',
},
authStorage
:
HosteDaySharedPreferencesAuthStorage
(
)
,
);
```

The authenticated session is restored after the application restarts.

## Memory storage

Use in-memory storage for tests or temporary sessions:

```dart
await
HosteDay.initializeApp
(
options: const <String, Object?>{
HosteDayOptionKeys.projectDomain:
'your-project.hosteday.com',
},
authStorage
:
MemoryHosteDayAuthStorage
(
)
,
);
```

Memory storage is cleared when the application process stops.

## Custom storage

Applications may implement `HosteDayAuthStorage` when a different persistence
mechanism is required:

```dart
class CustomAuthStorage implements HosteDayAuthStorage {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String key) async {
    return _values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}
```

---

# HTTP requests

Use `HosteDay.client` for custom API requests. The client handles URL building,
headers, optional bearer authentication, JSON encoding and decoding, timeouts,
validation errors, and network error conversion.

When the configured base URL already ends with `/api`, pass a resource path
such as `/posts`, not `/api/posts`.

```dart
await
HosteDay.client.get
('/posts
'
);
```

This resolves to:

```text
https://your-project.hosteday.com/api/posts
```

## Public and protected routes

Custom request methods default to `withAuth: false`.

Public route:

```dart

final response = await
HosteDay.client.get
('/posts
'
);
```

Protected route:

```dart

final response = await
HosteDay.client.get
('/posts
'
,withAuth:
true
,
);
```

`withAuth: true` adds:

```http
Authorization: Bearer USER_ACCESS_TOKEN
```

Use it only when the backend route is protected by user authentication.

## Automatic resource URL parameters

The high-level client accepts Dart-style parameter names and converts them to
the backend URL automatically:

| Dart parameter  | URL location | Backend name                      |
|-----------------|--------------|-----------------------------------|
| `id`            | Path segment | No query key; appended as `/{id}` |
| `search`        | Query string | `search`                          |
| `relationField` | Query string | `relation_field`                  |
| `relationValue` | Query string | `relation_value`                  |

Null optional values are omitted. Values are safely encoded by `Uri`.

Pass `relationField` and `relationValue` together. The relation field should
contain only letters, numbers, and underscores:

```text
^[a-zA-Z0-9_]+$
```

## GET index

List resources without an ID:

```dart

final response = await
HosteDay.client.get
('/posts
'
,search: 'flutter',
relationField: 'user_id',
relationValue
    :
'
019f3c33-3f79-733a-9d57-d949cccc90a6
'
,
);
```

Generated URL:

```text
/api/posts?search=flutter&relation_field=user_id&relation_value=019f3c33-3f79-733a-9d57-d949cccc90a6
```

## GET show

Show one resource by passing the ID separately:

```dart

final response = await
HosteDay.client.get
('/posts
'
,id: 12,
relationField: 'user_id',
relationValue:
'
019f3c33-3f79-733a-
9
d57
-
d949cccc90a6
'
,
);
```

Generated URL:

```text
/api/posts/12?relation_field=user_id&relation_value=019f3c33-3f79-733a-9d57-d949cccc90a6
```

An index request has no `id`. A show request includes `id`.

## POST create

Request body values remain inside `body`:

```dart

final response = await
HosteDay.client.post
('/posts
'
,body: <String, dynamic>{
'title': 'New post',
'body': 'Created from the Flutter application.',
'user_id': '019f3c33-3f79-733a-9d57-d949cccc90a6',
},
);
```

Example Laravel validation:

```json
{
  "body": "required|string|min:10",
  "title": "required|string|max:255",
  "user_id": "sometimes|string|max:255"
}
```

`user_id` is part of the JSON body. If it is optional and empty, omit it from
the map rather than sending an empty string:

```dart

final body = <String, dynamic>{
  'title': title,
  'body': postBody,
  if (userId.isNotEmpty) 'user_id': userId,
};
```

## PUT update

The ID is appended to the path. Relation parameters are placed in the URL, and
editable post values stay inside the JSON body:

```dart

final response = await
HosteDay.client.put
('/posts
'
,id: 12,
relationField: 'user_id',
relationValue: '019f3c33-3f79-733a-9d57-d949cccc90a6',
body: <String, dynamic>{
'title': 'Updated title',
'body': 'Updated post body with enough characters.',
'user_id': '019f3c33-3f79-733a-9d57-d949cccc90a6',
},
);
```

Generated URL:

```text
/api/posts/12?relation_field=user_id&relation_value=019f3c33-3f79-733a-9d57-d949cccc90a6
```

Example Laravel validation:

```json
{
  "id": [
    "required",
    "integer"
  ],
  "body": "sometimes|string|min:10",
  "title": "sometimes|string|max:255",
  "user_id": "sometimes|string|max:255",
  "relation_field": [
    "required",
    "string",
    "regex:/^[a-zA-Z0-9_]+$/"
  ],
  "relation_value": [
    "required"
  ]
}
```

Because editable fields use Laravel's `sometimes` rule, send only fields that
the user actually changed:

```dart

final updates = <String, dynamic>{
  if (titleChanged) 'title': title,
  if (bodyChanged) 'body': postBody,
  if (userIdChanged) 'user_id': userId,
};
```

## PATCH partial update

`PATCH` is useful when the backend supports partial updates. It uses the same
ID, relation parameters, body, authentication, headers, and timeout behavior as
`PUT`:

```dart

final response = await
HosteDay.client.patch
('/posts
'
,id: 12,
relationField: 'user_id',
relationValue: '019f3c33-3f79-733a-9d57-d949cccc90a6',
body: <String, dynamic>{
'title': 'Only the title changed',
},
);
```

Keep `patch()` only when the generated backend exposes a PATCH route. Otherwise
use `put()`.

## DELETE

Delete requests pass the ID and relation values in the URL:

```dart

final response = await
HosteDay.client.delete
('/posts
'
,id: 12,
relationField: 'user_id',
relationValue:
'
019f3c33-3f79-733a-
9
d57
-
d949cccc90a6
'
,
);
```

Generated URL:

```text
/api/posts/12?relation_field=user_id&relation_value=019f3c33-3f79-733a-9d57-d949cccc90a6
```

Example Laravel validation:

```json
{
  "id": [
    "required",
    "integer"
  ],
  "relation_field": [
    "required",
    "string",
    "regex:/^[a-zA-Z0-9_]+$/"
  ],
  "relation_value": [
    "required"
  ]
}
```

## Raw request

Use `request()` only when the method must be selected dynamically:

```dart

final response = await
HosteDay.client.request
(
method: 'POST',
path: '/posts',
body: <String, dynamic>{
'title': 'Created with a raw request',
'body': 'A complete body with at least ten characters.',
},
);
```

Prefer `get`, `post`, `put`, `patch`, and `delete` in normal application code.

---

# Reading API responses

Different Laravel endpoints may return lists in several shapes:

```json
{
  "data": []
}
```

Paginated response:

```json
{
  "data": {
    "data": []
  }
}
```

Named collection:

```json
{
  "posts": []
}
```

An example application may use a response reader to support all three shapes:

```dart
abstract final class ApiResponseReader {
  static List<Map<String, dynamic>> readList(Map<String, dynamic> response,) {
    final data = response['data'];

    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (response['posts'] is List) {
      return (response['posts'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return const <Map<String, dynamic>>[];
  }
}
```

Convert the list into models and sort it:

```dart

final posts = ApiResponseReader.readList(response)
    .map(PostModel.fromJson)
    .toList()
  ..sort(
        (a, b) => b.createdAtText.compareTo(a.createdAtText),
  );
```

The cascade operator `..sort(...)` sorts the created list itself and keeps the
same list as the expression result.

## Post model with user ID

```dart
class PostModel {
  final String id;
  final String userId;
  final String title;
  final String? body;
  final String createdAtText;
  final Map<String, dynamic> data;

  const PostModel({
    required this.id,
    required this.userId,
    required this.title,
    this.body,
    this.createdAtText = '',
    this.data = const <String, dynamic>{},
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id']?.toString() ?? '',
      userId: (json['user_id'] ??
          json['userId'] ??
          json['author_id'] ??
          json['owner_id'])
          ?.toString()
          .trim() ??
          '',
      title: json['title']?.toString() ?? 'Untitled post',
      body: json['body']?.toString(),
      createdAtText:
      (json['created_at'] ?? json['createdAt'])?.toString() ?? '',
      data: Map<String, dynamic>.from(json),
    );
  }
}
```

If the backend validates the ID as an integer, the update page can accept an
`Object` ID or convert a numeric string before sending it:

```dart

final postId = int.tryParse(post.id);

if (
postId == null) {
throw const FormatException('Post ID must be an integer.');
}
```

---

# Realtime

Realtime is available through:

```dart
HosteDay.realtime;HosteDay.client.realtime;
```

## Connect and disconnect

```dart
await
HosteDay.connectRealtime
();
```

```dart
await
HosteDay.disconnectRealtime
();
```

Check the current status:

```dart

final connected = HosteDay.realtime.isConnected;
```

Inspect the configured URL:

```dart
print
(
HosteDay
.
config
.
realtimeUrl
);
```

Example:

```text
wss://ws3.hosteday.com:443/app/YOUR_REALTIME_APP_KEY
```

## Public channel

Public channels do not require a signed-in user:

```dart
await
HosteDay.connectRealtime
();

final subscription = await
HosteDay.realtime.listenPublic
(
channel: 'posts',
event: 'PostCreated',
onEvent: (event) {
print(event.name);
print(event.channelName);
print(event.payload);
},
);
```

Cancel the subscription when it is no longer needed:

```dart
await
subscription.cancel
();
```

## Private channel

Private channels require a signed-in user:

```dart
await
HosteDay.connectRealtime
();

final subscription = await
HosteDay.realtime.listenPrivate
(
channel: 'orders.1',
event: 'OrderUpdated',
onEvent: (event) {
print(event.payload);
print(event.userId);
print(event.userName);
print(event.userEmail);
},
);
```

The SDK adds the `private-` prefix when needed.

## Presence channel

Presence channels require a signed-in user:

```dart
await
HosteDay.connectRealtime
();

final subscription = await
HosteDay.realtime.listenPresence
(
channel: 'chat.room.1',
event: 'MessageSent',
onEvent: (event) {
print(event.payload);
},
);
```

The SDK adds the `presence-` prefix when needed.

Listen for members joining or leaving:

```dart
await
HosteDay.realtime.listenPresenceMemberAdded
(
channel: 'chat.room.1',
onEvent: (event) {
print(event.payload);
},
);

await HosteDay.realtime.listenPresenceMemberRemoved(
channel: 'chat.room.1',
onEvent: (event) {
print(event.payload);
},
);
```

## Private encrypted channel

Encrypted channels require backend support:

```dart
await
HosteDay.realtime.listenPrivateEncrypted
(
channel: 'secure.orders.1',
event: 'SecureOrderUpdated',
onEvent: (event) {
print(event.payload);
},
);
```

## Unified listener

Use `listen()` when the channel type is selected dynamically:

```dart

final subscription = await
HosteDay.realtime.listen
(
channel: 'orders.1',
event: 'OrderUpdated',
type: HosteDayChannelType.private,
onEvent: (event) {
print(event.payload);
},
);
```

Supported channel types:

```dart
HosteDayChannelType.public;HosteDayChannelType.private;HosteDayChannelType
    .presence;HosteDayChannelType.privateEncrypted;
```

## Unsubscribe

```dart
await
HosteDay.realtime.unsubscribe
('orders.1
'
,type:
HosteDayChannelType
.
private
,
);
```

---

# Publishing realtime events

## Public event

```dart

final response = await
HosteDay.client.publishPublicEvent
(
channel: 'posts',
event: 'PostCreated',
payload: <String, dynamic>{
'post': <String, dynamic>{
'id': 1,
'title': 'New realtime post',
},
},
);
```

## Private event

A signed-in user is required:

```dart

final response = await
HosteDay.client.publishPrivateEvent
(
channel: 'orders.1',
event: 'OrderUpdated',
payload: <String, dynamic>{
'order_id': 1,
'status': 'paid',
},
);
```

## Presence event

A signed-in user is required:

```dart

final response = await
HosteDay.client.publishPresenceEvent
(
channel: 'chat.room.1',
event: 'MemberTyping',
payload: <String, dynamic>{
'typing': true,
},
);
```

---

# Realtime event object

Realtime callbacks receive a `HosteDayRealtimeEvent`:

```dart
await
HosteDay.realtime.listenPublic
(
channel: 'posts',
event: 'PostCreated',
onEvent: (event) {
print(event.name);
print(event.channelName);
print(event.payload);
print(event.data);
print(event.message);
print(event.user);
print(event.userId);
print(event.userName);
print(event.userEmail);
},
);
```

Access payload values directly:

```dart

final title = event['title'];
final post = event['post'];

if (
event.containsKey('post')) {
print(event['post']);
}
```

---

# Error handling

Most API and network failures throw `HosteDayException`:

```dart
try {
final response = await HosteDay.client.get('/posts');
print(response);
} on HosteDayException catch (error) {
print(error.message);
print(error.statusCode);
print(error.displayMessage);
} catch (error) {
print(error);
}
```

## Validation errors

Laravel-style validation responses are exposed through `validationErrors`:

```json
{
  "message": "The email field is required.",
  "errors": {
    "email": [
      "The email field is required."
    ],
    "password": [
      "The password field is required."
    ]
  }
}
```

```dart
try {
await HosteDay.auth.signInWithEmailAndPassword(
email: email,
password: password,
);
} on HosteDayException catch (error) {
print(error.firstErrorFor('email'));
print(error.firstErrorFor('password'));
print(error.displayMessage);
}
```

Useful helpers include:

```dart
error.hasValidationErrors;error.isValidationError;error.isUnauthenticated;error.isForbidden;error
    .isNotFound;error.isServerError;error.firstValidationError;error.displayMessage;
```

## `Unauthenticated.` with status 401

A visible user in the Flutter interface does not prove that a custom backend
route accepts the current token. Check these cases:

1. The request uses the correct project domain and API base URL.
2. The backend route is actually protected by user authentication.
3. `withAuth: true` is used only for protected routes.
4. The user token belongs to the same HosteDay project and authentication
   system as the target API.
5. The token has not expired or been revoked.
6. The backend guard accepts the token type issued by the login endpoint.
7. Redirects or proxies do not remove the `Authorization` header.

If the custom route is public, call it with the default `withAuth: false`:

```dart
await
HosteDay.client.post
('/posts
'
,body: <String, dynamic>{
'title': 'Public post',
'body': 'A public post body with enough characters.',
},
);
```

If a public route still returns `Unauthenticated.`, the authentication failure
is coming from backend route configuration, middleware, controller code, model
observers, policies, or a service called by that route. Inspect the backend
route and middleware list.

The `X-Api-Token` project key does not replace the bearer token. Removing or
adding it cannot fix an incompatible user authentication guard.

Never publish or log the complete bearer token. Revoke any token that has been
shared publicly.

## `Data too long for column 'body'`

This database error means the request passed application validation but the
database column is too short for the submitted text. A `VARCHAR(255)` column
cannot store a long post body.

Use a `TEXT` or `LONGTEXT` column when long bodies are allowed:

```php
Schema::table('posts', function (Blueprint $table) {
    $table->text('body')->change();
});
```

Also align request validation with the database capacity, for example:

```php
'body' => ['required', 'string', 'min:10', 'max:10000'],
```

---

# Fixed HosteDay endpoints

Authentication and user endpoints are managed internally by HosteDay and are
not initialization options:

```text
POST   /api/auth/login
POST   /api/auth/register
POST   /api/auth/forgot-password
GET    /api/user
PUT    /api/user
POST   /api/user/avatar
DELETE /api/user
POST   /api/logout
POST   /api/email/verification-notification
```

Realtime authorization and publishing endpoints are also managed by the SDK:

```text
POST /api/realtime/events/public
POST /api/realtime/events/private
POST /api/realtime/events/presence
POST /api/broadcasting/auth-manual
```

Use `HosteDay.client` for project-specific resources such as posts, orders, and
products.

---

# Expected authentication responses

## Sign-in response

Recommended shape:

```json
{
  "access_token": "1|example-token",
  "token_type": "Bearer",
  "expires_in": null,
  "user": {
    "id": 1,
    "name": "Mustafa",
    "email": "mustafa@example.com",
    "email_verified_at": "2026-07-08T10:00:00.000000Z",
    "avatar": "https://project.hosteday.com/users/1/avatar.png"
  }
}
```

The SDK also accepts `token`, nested `data`, and common user field aliases.

Supported token keys:

```text
access_token
accessToken
token
```

Supported user ID keys:

```text
id
user_id
uuid
```

Supported user name keys:

```text
name
display_name
displayName
full_name
fullName
```

Supported avatar keys:

```text
avatar_url
avatarUrl
avatar
photo_url
photoUrl
image
image_url
imageUrl
```

Email verification keys:

```text
email_verified
emailVerified
email_verified_at
emailVerifiedAt
```

---

# Application navigation example

A common posts flow is:

```text
HomePage
└── Index
    ├── CreatePage
    └── Show
        ├── UpdatePage
        └── Delete confirmation
```

The index page should focus on loading, displaying, refreshing, and optionally
listening for posts. Keep create, update, show, and delete responsibilities in
their own pages or widgets.

A `PostCard` can open the update page and refresh the index after success:

```dart

final updated = await
Navigator.of
(
context).push<bool>(
MaterialPageRoute<bool>(
builder: (_) => UpdatePage(
postId: int.parse(post.id),
relationField: 'user_id',
relationValue: post.userId,
),
),
);

if (updated == true) {
await reloadPosts();
}
```

---

# Example application

A complete example is included in the repository:

```text
example/
```

It demonstrates:

- SDK initialization.
- Persistent authentication sessions.
- Sign in and registration.
- Navigation to the home page after authentication.
- Password-reset and email-verification requests.
- A shared authentication-aware AppBar.
- Profile updates.
- Avatar selection and upload.
- Full HTTPS avatar display.
- Posts index, show, create, update, and delete flows.
- `user_id` inside create and update request bodies.
- Automatic `id`, `search`, `relation_field`, and `relation_value` URL values.
- Public and protected API calls.
- Realtime listening and publishing.

See `example/README.md` for the example-specific architecture and complete page
flow.

---

# Migration notes

## Low-level HTTP client

Old application code may import or call `HosteDayHttpClient` directly. New code
should call `HosteDay.client` instead.

Remove this public export:

```dart
export 'src/http/hosteday_http_client.dart';
```

## Resource URL construction

Old application code may manually write query names:

```dart
queryParameters: <
String, Object?>{
'relation_field': 'user_id',
'relation_value': userId,
}
```

New code passes values directly:

```dart
await
HosteDay.client.get
('/posts
'
,relationField: 'user_id',
relationValue: userId,
);
```

Old show, update, or delete code may append the ID manually:

```dart
await
HosteDay.client.get
('/posts/
$postId'
);
```

New code can pass the ID separately:

```dart
await
HosteDay.client.get
('/posts
'
,id:
postId
,
);
```

## Project API token name

Old name:

```dart
HosteDayOptionKeys.apiToken
```

Current name:

```dart
HosteDayOptionKeys.projectApiKey
```

The current name prevents confusion with the signed-in user's access token.

## Realtime key name

Old name:

```dart
HosteDayOptionKeys.pusherKey
```

Current name:

```dart
HosteDayOptionKeys.realtimeAppKey
```

HosteDay uses a Pusher-compatible protocol, but application developers do not
need a Pusher account.

## Global class name

Old name:

```dart
Hosteday
```

Current name:

```dart
HosteDay
```

Use `HosteDay` in all new code.

---

Turn your ideas into production-ready applications without spending time on server provisioning, API
infrastructure, authentication, databases, file storage, or realtime configuration. HosteDay brings
these services together in one developer-friendly platform, so you can focus on building the
experience your users need. Create your project and start building today
at [hosteday.com](https://hosteday.com/).

---

# Security notes

- Do not hard-code production credentials in public repositories.
- Do not configure placeholder project API keys in production.
- Do not print complete bearer tokens or authorization headers.
- Use `withAuth: true` only for routes protected by user authentication.
- Validate authorization and relation ownership on the backend.
- Validate relation field names against an allowlist when possible.
- Validate avatar MIME type, size, and extension on the backend.
- Return file and avatar links through HTTPS.
- Use private or presence realtime channels for sensitive data.
- Do not treat client-side checks as a security boundary.
- Revoke tokens that were exposed in logs, screenshots, or messages.

---

# License

MIT