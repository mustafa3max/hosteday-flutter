# HosteDay Flutter

[![pub package](https://img.shields.io/pub/v/hosteday_flutter.svg)](https://pub.dev/packages/hosteday_flutter)
[![platform](https://img.shields.io/badge/platform-Flutter-blue.svg)](https://flutter.dev)
[![license](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A Flutter SDK for connecting applications to HosteDay APIs, authentication,
persistent sessions, user management, avatar uploads, custom backend endpoints,
and realtime services.

`hosteday_flutter` gives Flutter developers a simple Firebase-inspired API for:

- Initializing a HosteDay project.
- Signing users in and out.
- Creating user accounts.
- Persisting authenticated sessions.
- Sending password reset emails.
- Sending email verification emails.
- Reading and updating the current user.
- Uploading the current user's avatar.
- Calling custom backend APIs.
- Sending authenticated API requests.
- Connecting to HosteDay realtime channels.
- Listening to public, private, presence, and encrypted realtime events.
- Publishing realtime events through HosteDay.

![Flutter Example App](https://raw.githubusercontent.com/mustafa3max/hosteday-flutter/master/assets/flutter-example.png)

---

## HosteDay platform

This package is designed to work with the HosteDay platform.

HosteDay is a backend and API platform that lets developers create isolated APIs
for their projects without manually configuring Docker, databases, routing,
HTTPS, authentication, or infrastructure.

Each project can receive:

- An isolated runtime environment.
- A project database.
- A generated API.
- An HTTPS-enabled project domain.
- Authentication and user endpoints.
- File storage.
- Realtime services.

To use this Flutter SDK, first create a project from the HosteDay dashboard.
HosteDay then provides the values required by the Flutter app:

- Project domain, such as `your-project.hosteday.com`.
- Project API key, used as `HosteDayOptionKeys.projectApiKey`.
- Realtime app key, used as `HosteDayOptionKeys.realtimeAppKey`.
- Realtime host, used as `HosteDayOptionKeys.realtimeHost`.

A typical workflow is:

1. Create a project from the HosteDay dashboard.
2. Define database tables such as `posts`, `orders`, or `products`.
3. Let HosteDay generate the project API.
4. Copy the project domain and project API key.
5. Enable realtime when needed.
6. Initialize `hosteday_flutter` with those values.

Example:

```dart
await
HosteDay.initializeApp
(
options: const <String, Object?>{
HosteDayOptionKeys.projectDomain:
'your-project.hosteday.com',
HosteDayOptionKeys.projectApiKey:
'YOUR_PROJECT_API_KEY',

// Required only when using HosteDay realtime.
HosteDayOptionKeys.realtimeAppKey:
'YOUR_REALTIME_APP_KEY',
HosteDayOptionKeys.realtimeHost:
'ws3.hosteday.com',
},
authStorage
:
HosteDaySharedPreferencesAuthStorage
(
)
,
);
```

The project API key identifies the HosteDay project. It is not the signed-in
user's access token.

After a user signs in, HosteDay Auth manages the user access token
automatically. Use `withAuth: true` when calling protected project endpoints:

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

Realtime also uses the authenticated user token automatically when subscribing
to private or presence channels.

---

## Installation

Add the package to your Flutter project:

```bash
flutter pub add hosteday_flutter
```

Import it:

```dart
import 'package:hosteday_flutter/hosteday_flutter.dart';
```

For avatar selection from the gallery or camera, add `image_picker` to the
application that uses the SDK:

```bash
flutter pub add image_picker
```

The SDK itself accepts image bytes and does not force applications to use a
specific file picker.

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

      // This is the project API key, not a user token.
      HosteDayOptionKeys.projectApiKey:
      'YOUR_PROJECT_API_KEY',
    },
    authStorage: HosteDaySharedPreferencesAuthStorage(),
  );

  runApp(const App());
}
```

---

## Important naming notes

### Project API key

Use:

```dart
HosteDayOptionKeys.projectApiKey
```

The project API key identifies the HosteDay project. It is not the
authenticated user's access token.

The SDK sends it automatically using the configured project header, which
defaults to:

```http
X-Api-Token: YOUR_PROJECT_API_KEY
```

### User access token

The user access token is created after sign in.

Applications do not pass it manually. The SDK stores it and uses it
automatically for protected requests:

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

### Realtime app key

Use:

```dart
HosteDayOptionKeys.realtimeAppKey
```

This key is provided by HosteDay for realtime connections.

Developers do not need a Pusher account. HosteDay uses a Pusher-compatible
realtime protocol internally.

---

## Basic initialization

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

---

## Initialization with realtime

```dart
await
HosteDay.initializeApp
(
options: const <String, Object?>{
HosteDayOptionKeys.projectDomain:
'your-project.hosteday.com',
HosteDayOptionKeys.projectApiKey:
'YOUR_PROJECT_API_KEY',
HosteDayOptionKeys.realtimeAppKey:
'YOUR_REALTIME_APP_KEY',
HosteDayOptionKeys.realtimeHost:
'ws3.hosteday.com',
HosteDayOptionKeys.realtimeScheme:
'wss',
HosteDayOptionKeys.realtimePort:
443,
},
authStorage
:
HosteDaySharedPreferencesAuthStorage
(
)
,
);
```

Realtime is not connected automatically unless requested:

```dart
await
HosteDay.connectRealtime
();
```

To initialize and connect immediately:

```dart
await
HosteDay.initializeApp
(
options: const <String, Object?>{
HosteDayOptionKeys.projectDomain:
'your-project.hosteday.com',
HosteDayOptionKeys.projectApiKey:
'YOUR_PROJECT_API_KEY',
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

## Using environment variables

Compile-time environment variables are recommended for examples and local
development.

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

The first argument of `String.fromEnvironment` must be the environment variable
name, not the actual domain.

Correct:

```dart

static const String projectDomain = String.fromEnvironment(
  'HOSTEDAY_PROJECT_DOMAIN',
  defaultValue: 'your-project.hosteday.com',
);
```

Incorrect:

```dart

static const String projectDomain = String.fromEnvironment(
  'https://your-project.hosteday.com',
  defaultValue: 'project.hosteday.com',
);
```

---

## Main SDK entry point

The official SDK entry point is:

```dart
HosteDay
```

Available global accessors:

```dart
HosteDay.client;HosteDay.auth;HosteDay.config;HosteDay.http;HosteDay.realtime;HosteDay
    .isInitialized;
```

Example:

```dart

final client = HosteDay.client;
final auth = HosteDay.auth;
final config = HosteDay.config;
```

---

## Auth state gate

Use `authStateChanges()` to switch between signed-in and signed-out screens.

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

        return HomePage(user: user);
      },
    );
  }
}
```

---

# Authentication

## Sign in with email and password

```dart
try {
final credential =
await HosteDay.auth.signInWithEmailAndPassword(
email: 'user@example.com',
password: 'password123',
);

final user = credential.user;
final session = credential.session;

print(user.id);
print(user.email);
print(session.accessToken);
} on HosteDayException catch (error) {
print(error.displayMessage);
}
```

After successful sign in, HosteDay automatically:

- Saves the session.
- Saves the access token.
- Updates `currentUser`.
- Emits auth state changes.
- Uses the token for protected API requests.
- Uses the token for private and presence channel authorization.

---

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

Additional registration fields can be passed through `additionalData`:

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

Authentication and user endpoints are owned by HosteDay and are not intended to
be changed by application developers.

---

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

---

## Listen to user changes

```dart

final subscription =
HosteDay.auth.userChanges().listen((user) {
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

---

## Reload user from the server

Use this after updating the profile, verifying an email through a web link, or
when fresh user data is required.

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

---

## Update user profile

```dart
try {
final user = await HosteDay.auth.updateProfile(
<String, dynamic>{
'name': 'Mustafa Max',
},
);

print(user.displayName);
} on HosteDayException catch (error) {
print(error.displayMessage);
}
```

The accepted fields depend on the HosteDay project backend.

---

## Upload user avatar

`updateAvatar()` accepts raw image bytes and a supported file extension.

Supported extensions:

```txt
jpg
jpeg
png
webp
```

Add `image_picker` to the Flutter application:

```bash
flutter pub add image_picker
```

Select and upload an image:

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

  if (dotIndex == -1 ||
      dotIndex == image.name.length - 1) {
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

The SDK converts the bytes to Base64 and sends a request equivalent to:

```json
{
  "bytes": "BASE64_ENCODED_IMAGE_BYTES",
  "extension": "png"
}
```

The application should not add a prefix such as:

```txt
data:image/png;base64,
```

The SDK sends the Base64 value expected by the HosteDay API.

### Avatar URL

The backend can store only a relative path in the database:

```txt
users/USER_ID/IMAGE.png
```

When returning the user, the API should provide a complete HTTPS URL:

```json
{
  "avatar": "https://project.hosteday.com/users/USER_ID/IMAGE.png"
}
```

The complete URL is available through:

```dart

final user = HosteDay.auth.currentUser;

final photoUrl = user?.photoUrl;
final avatarUrl = user?.avatarUrl;
```

Display the avatar:

```dart

final avatarUrl = user.avatarUrl;

CircleAvatar
(
radius: 48,
backgroundImage:
avatarUrl != null && avatarUrl.isNotEmpty
? NetworkImage(avatarUrl)
    : null,
child: avatarUrl == null || avatarUrl.isEmpty
? const Icon(Icons.person)
    : null,
);
```

Use `userChanges()` to refresh the interface automatically after an avatar
upload:

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
backgroundImage:
avatarUrl != null && avatarUrl.isNotEmpty
? NetworkImage(avatarUrl)
    : null,
child: avatarUrl == null || avatarUrl.isEmpty
? const Icon(Icons.person)
    : null,
);
},
);
```

### Android configuration

Add the camera permission to:

```txt
android/app/src/main/AndroidManifest.xml
```

Place it inside the `<manifest>` element:

```xml

<uses-permission android:name="android.permission.CAMERA" />
```

Current Android versions normally do not require legacy storage permissions for
gallery selection through `image_picker`.

### iOS configuration

Add the following entries to:

```txt
ios/Runner/Info.plist
```

```xml

<key>NSPhotoLibraryUsageDescription</key><string>Select a profile picture.</string>

<key>NSCameraUsageDescription</key><string>Take a profile picture.</string>
```

### Web configuration

Gallery selection works through the browser file picker.

Camera capture depends on browser capabilities and user permissions.

---

## Send email verification

```dart
try {
await HosteDay.auth.sendEmailVerification();

print('Verification email sent.');
} on HosteDayException catch (error) {
print(error.displayMessage);
}
```

The Flutter app only requests the verification email. Verification is completed
through the web link sent to the user.

---

## Send password reset email

```dart
try {
await HosteDay.auth.sendPasswordResetEmail(
email: 'user@example.com',
);

print('Password reset email sent.');
} on HosteDayException catch (error) {
print(error.displayMessage);
}
```

The Flutter app only requests the password reset email. Password reset is
completed through the web link sent to the user.

---

## Sign out

```dart
await
HosteDay.auth.signOut
();
```

When signing out, HosteDay:

- Attempts to call the remote logout endpoint.
- Clears the local session.
- Clears the local access token.
- Sets `currentUser` to `null`.
- Emits `null` through auth streams.
- Disconnects realtime.

The local session is cleared even when the remote logout request fails.

---

# Session storage

## Recommended storage

Use:

```dart
HosteDaySharedPreferencesAuthStorage
()
```

Example:

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

This stores the authenticated session using `shared_preferences`.

The user remains signed in after closing and reopening the application.

The package already depends on `shared_preferences`, so applications do not
need to install it separately only for HosteDay session storage.

---

## Memory storage

For tests or temporary sessions:

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

Memory storage is cleared when the application process restarts.

---

## Custom storage

Applications can implement their own storage:

```dart
class CustomAuthStorage implements HosteDayAuthStorage {
  final Map<String, String> _values =
  <String, String>{};

  @override
  Future<String?> read(String key) async {
    return _values[key];
  }

  @override
  Future<void> write(String key,
      String value,) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}
```

Use the custom storage during initialization:

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
CustomAuthStorage
(
)
,
);
```

---

# HTTP requests

Use `HosteDay.client` for custom backend API requests.

## Public GET request

```dart

final response = await
HosteDay.client.get
('/api/posts
'
,
);

print(
response
);
```

---

## Authenticated GET request

```dart

final response = await
HosteDay.client.get
('/api/posts
'
,withAuth: true,
);

print(response);
```

This automatically sends:

```http
Authorization: Bearer USER_ACCESS_TOKEN
```

---

## GET with query parameters

```dart

final response = await
HosteDay.client.http.get
('/api/posts
'
,withAuth: true,
queryParameters: <String, Object?>{
'page': 1,
'search': 'flutter',
},
);

print
(
response
);
```

---

## Get one post

```dart

final response = await
HosteDay.client.get
('/api/posts/1
'
,withAuth: true,
);

final post = response['data'];

print(post);
```

Expected response:

```json
{
  "data": {
    "id": 1,
    "title": "First post",
    "body": "Post body"
  }
}
```

---

## Create a post

```dart

final response = await
HosteDay.client.post
('/api/posts
'
,withAuth: true,
body: <String, dynamic>{
'title': 'New post',
'body': 'Created from Flutter.',
},
);

print
(
response
);
```

---

## Update a post with PUT

```dart

final response = await
HosteDay.client.put
('/api/posts/1
'
,withAuth: true,
body: <String, dynamic>{
'title': 'Updated post title',
'body': 'Updated post body.',
},
);

print
(
response
);
```

---

## Partially update a post with PATCH

```dart

final response = await
HosteDay.client.patch
('/api/posts/1
'
,withAuth: true,
body: <String, dynamic>{
'status': 'published',
},
);

print
(
response
);
```

---

## Delete a post

```dart
await
HosteDay.client.delete
('/api/posts/1
'
,withAuth:
true
,
);
```

---

## Raw request

```dart

final response = await
HosteDay.client.request
(
method: 'POST',
path: '/api/posts',
withAuth: true,
body: <String, dynamic>{
'title': 'Created with raw request',
},
);

print
(
response
);
```

---

## Request timeout

When using the lower-level HTTP client:

```dart

final response = await
HosteDay.client.http.get
('/api/posts
'
,withAuth: true,
timeout: const Duration(seconds: 10
)
,
);
```

---

# Custom model example

API responses can be converted into application models.

```dart
class Post {
  final int id;
  final String title;
  final String? body;

  const Post({
    required this.id,
    required this.title,
    this.body,
  });

  factory Post.fromJson(Map<String, dynamic> json,) {
    return Post(
      id: int.parse(json['id'].toString()),
      title: json['title'].toString(),
      body: json['body']?.toString(),
    );
  }
}
```

Load posts:

```dart

final response = await
HosteDay.client.get
('/api/posts
'
,withAuth: true,
);

final data = response['data'];

final posts = data is List
? data
    .whereType<Map>()
    .map(
(item) => Post.fromJson(
Map<String, dynamic>.from(item),
),
)
    .toList()
    : <Post>[];

print(posts.
length
);
```

Load one post:

```dart

final response = await
HosteDay.client.get
('/api/posts/1
'
,withAuth: true,
);

final post = Post.fromJson(
Map<String, dynamic>.from(
response['data'] as Map,
),
);

print(post.title);
```

---

# Realtime

HosteDay realtime is available through:

```dart
HosteDay.realtime
```

or:

```dart
HosteDay.client.realtime
```

---

## Connect realtime

```dart
await
HosteDay.connectRealtime
();
```

---

## Disconnect realtime

```dart
await
HosteDay.disconnectRealtime
();
```

---

## Check realtime status

```dart

final connected = HosteDay.realtime.isConnected;

print(connected);
```

---

## Inspect realtime URL

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

---

## Listen to a public channel

Public channels do not require a signed-in user.

```dart
await
HosteDay.connectRealtime
();

final subscription =
    await
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

Cancel when no longer needed:

```dart
await
subscription.cancel
();
```

---

## Listen to a private channel

Private channels require a signed-in user.

```dart
await
HosteDay.auth.signInWithEmailAndPassword
(
email: 'user@example.com',
password: 'password123',
);

await HosteDay.connectRealtime();

final subscription =
await HosteDay.realtime.listenPrivate(
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

The SDK automatically adds the `private-` prefix when needed.

```dart
channel: '
orders.1
'
```

becomes:

```text
private-orders.1
```

---

## Listen to a presence channel

Presence channels require a signed-in user.

```dart
await
HosteDay.connectRealtime
();

await
HosteDay.realtime.listenPresence
(
channel: 'chat.room.1',
event: 'MessageSent',
onEvent: (event) {
print(event.payload);
},
);
```

The SDK automatically adds the `presence-` prefix when needed.

---

## Listen for presence members joining

```dart
await
HosteDay.realtime.listenPresenceMemberAdded
(
channel: 'chat.room.1',
onEvent: (event) {
print('Member joined');
print(event.payload);
},
);
```

---

## Listen for presence members leaving

```dart
await
HosteDay.realtime.listenPresenceMemberRemoved
(
channel: 'chat.room.1',
onEvent: (event) {
print('Member left');
print(event.payload);
},
);
```

---

## Listen to a private encrypted channel

Private encrypted channels require backend support.

```dart
await
HosteDay.connectRealtime
();

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

---

## Unified realtime listener

Use `listen()` when the channel type is selected dynamically.

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
HosteDayChannelType.public
HosteDayChannelType.private
HosteDayChannelType.presence
HosteDayChannelType.privateEncrypted
```

---

## Unsubscribe from one channel

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

## Publish a public event

```dart

final response =
    await
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

print
(
response
);
```

---

## Publish a private event

A signed-in user is required.

```dart

final response =
    await
HosteDay.client.publishPrivateEvent
(
channel: 'orders.1',
event: 'OrderUpdated',
payload: <String, dynamic>{
'order_id': 1,
'status': 'paid',
},
);

print
(
response
);
```

The SDK automatically adds the `private-` prefix when needed.

---

## Publish a presence event

A signed-in user is required.

```dart

final response =
    await
HosteDay.client.publishPresenceEvent
(
channel: 'chat.room.1',
event: 'MemberTyping',
payload: <String, dynamic>{
'typing': true,
},
);

print
(
response
);
```

The SDK automatically adds the `presence-` prefix when needed.

---

# Realtime event object

Realtime callbacks receive a `HosteDayRealtimeEvent`.

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

Access payload fields directly:

```dart

final title = event['title'];
final post = event['post'];
```

Check whether a key exists:

```dart
if (event.containsKey('post')) {
print(event['post']);
}
```

---

# Error handling

Most API and network failures throw `HosteDayException`.

```dart
try {
final response = await HosteDay.client.get(
'/api/posts',
withAuth: true,
);

print(response);
} on HosteDayException catch (error) {
print(error.message);
print(error.statusCode);
print(error.displayMessage);
} catch (error) {
print(error);
}
```

---

## Validation errors

Laravel-style validation responses are available through
`validationErrors`.

Example API response:

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

Handle validation errors:

```dart
try {
await HosteDay.auth.signInWithEmailAndPassword(
email: email,
password: password,
);
} on HosteDayException catch (error) {
final emailError =
error.firstErrorFor('email');
final passwordError =
error.firstErrorFor('password');

print(emailError);
print(passwordError);
print(error.displayMessage);
}
```

Useful helpers:

```dart
error.hasValidationErrors;error.isValidationError;error.isUnauthenticated;error.isForbidden;error
    .isNotFound;error.isServerError;error.firstValidationError;error.displayMessage;
```

---

# Configuration options

## Required options

| Option                             | Description                                                   |
|------------------------------------|---------------------------------------------------------------|
| `HosteDayOptionKeys.projectDomain` | HosteDay project domain, such as `your-project.hosteday.com`. |

## Optional options

| Option                              | Description                                            |
|-------------------------------------|--------------------------------------------------------|
| `HosteDayOptionKeys.apiBaseUrl`     | Custom API base URL. Usually not required.             |
| `HosteDayOptionKeys.baseUrl`        | Alias for `apiBaseUrl`.                                |
| `HosteDayOptionKeys.projectApiKey`  | Project API key sent using the project API header.     |
| `HosteDayOptionKeys.apiTokenHeader` | Custom project API key header. Default: `X-Api-Token`. |
| `HosteDayOptionKeys.realtimeAppKey` | HosteDay realtime app key.                             |
| `HosteDayOptionKeys.realtimeHost`   | Realtime WebSocket host.                               |
| `HosteDayOptionKeys.realtimeScheme` | `ws` or `wss`. Default: `wss`.                         |
| `HosteDayOptionKeys.realtimePort`   | Realtime port. Default: `443` for `wss`.               |

---

## Fixed HosteDay endpoints

Authentication and user endpoints are fixed by HosteDay and are not
configurable through `initializeApp`.

The SDK manages these endpoints internally:

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

Realtime publishing and authorization endpoints are also managed internally:

```text
POST /api/realtime/events/public
POST /api/realtime/events/private
POST /api/realtime/events/presence
POST /api/broadcasting/auth-manual
```

Use `HosteDay.client.get`, `post`, `put`, `patch`, and `delete` for custom
project endpoints such as:

```text
/api/posts
/api/orders
/api/products
```

---

# Expected backend responses

## Sign in response

Recommended response:

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

The SDK also accepts:

```json
{
  "token": "1|example-token",
  "user": {
    "id": 1,
    "name": "Mustafa",
    "email": "mustafa@example.com"
  }
}
```

Nested data is also supported:

```json
{
  "data": {
    "access_token": "1|example-token",
    "user": {
      "id": 1,
      "name": "Mustafa",
      "email": "mustafa@example.com"
    }
  }
}
```

---

## Avatar response

After uploading an avatar, the endpoint should return the updated user or allow
the SDK to reload it.

Recommended response:

```json
{
  "success": true,
  "message": "Avatar updated successfully.",
  "data": {
    "id": "USER_ID",
    "name": "Example User",
    "email": "user@example.com",
    "avatar": "https://project.hosteday.com/users/USER_ID/IMAGE.png"
  }
}
```

The database can store:

```text
users/USER_ID/IMAGE.png
```

while the API resource returns:

```text
https://project.hosteday.com/users/USER_ID/IMAGE.png
```

The API should prefer HTTPS links.

---

## Supported token keys

```text
access_token
accessToken
token
```

## Supported user ID keys

```text
id
user_id
uuid
```

## Supported user name keys

```text
name
display_name
displayName
full_name
fullName
```

## Supported avatar keys

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

## Email verification keys

The SDK can detect verified users from:

```text
email_verified
emailVerified
email_verified_at
emailVerifiedAt
```

---

# Full quick example

```dart
import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HosteDay.initializeApp(
    options: const <String, Object?>{
      HosteDayOptionKeys.projectDomain:
      'your-project.hosteday.com',
      HosteDayOptionKeys.projectApiKey:
      'YOUR_PROJECT_API_KEY',
    },
    authStorage:
    HosteDaySharedPreferencesAuthStorage(),
  );

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<HosteDayUser?>(
        stream:
        HosteDay.auth.authStateChanges(),
        initialData:
        HosteDay.auth.currentUser,
        builder: (context, snapshot) {
          final user = snapshot.data;

          if (user == null) {
            return const SignInPage();
          }

          return HomePage(user: user);
        },
      ),
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() =>
      _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    setState(() {
      loading = true;
    });

    try {
      await HosteDay.auth
          .signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );
    } on HosteDayException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              error.displayMessage,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            TextField(
              controller: email,
              decoration:
              const InputDecoration(
                labelText: 'Email',
              ),
            ),
            TextField(
              controller: password,
              obscureText: true,
              decoration:
              const InputDecoration(
                labelText: 'Password',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed:
              loading ? null : signIn,
              child: Text(
                loading
                    ? 'Signing in...'
                    : 'Sign in',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    required this.user,
    super.key,
  });

  final HosteDayUser user;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HosteDay'),
        actions: <Widget>[
          IconButton(
            icon:
            const Icon(Icons.logout),
            onPressed: () {
              HosteDay.auth.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircleAvatar(
              radius: 42,
              backgroundImage:
              avatarUrl != null &&
                  avatarUrl.isNotEmpty
                  ? NetworkImage(
                avatarUrl,
              )
                  : null,
              child: avatarUrl == null ||
                  avatarUrl.isEmpty
                  ? const Icon(
                Icons.person,
              )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              'Welcome '
                  '${user.displayName ?? user.email ?? user.id}',
            ),
          ],
        ),
      ),
    );
  }
}
```

---

# Example app

A complete Flutter example is included in this repository:

```text
example/
```

Useful files:

```text
example/README.md
example/EXAMPLE.md
example/lib/main.dart
example/lib/app.dart
```

The example demonstrates:

- SDK initialization.
- Session persistence.
- Sign in.
- Registration.
- Password reset email.
- Auth gate.
- Current user display.
- Profile update.
- Avatar selection and upload.
- Full HTTPS avatar display.
- Email verification requests.
- Posts API usage.
- Realtime listening.
- Realtime publishing.

---

# Migration notes

## Old project API token name

Old name:

```dart
HosteDayOptionKeys.apiToken
```

New name:

```dart
HosteDayOptionKeys.projectApiKey
```

Reason: `apiToken` can be confused with the signed-in user's access token.

## Old realtime key name

Old name:

```dart
HosteDayOptionKeys.pusherKey
```

New name:

```dart
HosteDayOptionKeys.realtimeAppKey
```

Reason: HosteDay uses a Pusher-compatible protocol, but developers do not need a
Pusher account.

## Old global class name

Old name:

```dart
Hosteday
```

New name:

```dart
HosteDay
```

Use `HosteDay` in all new code.

---

# Security notes

- Do not hard-code production project API keys in public repositories.
- Do not expose user access tokens manually.
- Use `withAuth: true` for protected requests.
- Validate authorization on the backend.
- Validate tenant ownership on the backend.
- Validate avatar MIME type, size, and file extension on the backend.
- Return avatar links through HTTPS.
- Use private or presence realtime channels for sensitive data.
- Do not rely on client-side checks as a security boundary.
- Revoke or invalidate user tokens server-side when needed.

---

# License

This project is licensed under the [MIT License](LICENSE).