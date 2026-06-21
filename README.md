# HosteDay Flutter

[![pub package](https://img.shields.io/pub/v/hosteday_flutter.svg)](https://pub.dev/packages/hosteday_flutter)
[![platform](https://img.shields.io/badge/platform-Flutter-blue.svg)](https://flutter.dev)
[![license](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A Flutter and Dart SDK for connecting applications to HosteDay APIs, authentication, and
Pusher-compatible real-time services.

`hosteday_flutter` provides a single SDK entry point for:

* Firebase-inspired authentication and session management.
* Automatic access-token handling for protected API requests.
* User profile management and password reset flows.
* Custom HTTP requests through `GET`, `POST`, `PUT`, `PATCH`, and `DELETE`.
* Public, private, presence, and private encrypted Realtime channels.
* Automatic authenticated channel authorization after sign-in.
* Configurable API endpoints and project-level request protection.

![Flutter Example App](https://raw.githubusercontent.com/mustafa3max/hosteday-flutter/master/assets/flutter-example.png)

---

## Features

* Global SDK initialization through `HosteDay.initializeApp(...)`.
* Firebase-style authentication API through `HosteDay.auth`.
* Persistent or temporary user sessions through `HosteDayAuthStorage`.
* Automatic session restoration during application startup.
* Automatic access-token usage for requests with `withAuth: true`.
* Automatic token usage for private, presence, and private encrypted Realtime channels.
* Authentication state streams:

    * `authStateChanges()`
    * `idTokenChanges()`
    * `userChanges()`
* Built-in authentication operations:

    * Sign in
    * Register
    * Sign out
    * Password reset
    * Profile reload
    * Profile update
    * Email verification request
* Structured errors through:

    * `HosteDayException`
    * `HosteDayAuthException`
* Realtime defaults:

    * Scheme: `wss`
    * Port: `443`
* Complete WebSocket endpoint through `HosteDay.config.realtimeUrl`.

---

## Installation

Add the package to your Flutter project:

```bash
flutter pub add hosteday_flutter
```

Then import it:

```dart
import 'package:hosteday_flutter/hosteday_flutter.dart';
```

---

## Quick Start

Initialize HosteDay once before running the application:

```dart
import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HosteDay.initializeApp(
    options: const <String, Object?>{
      HosteDayOptionKeys.projectDomain: 'your-project.hosteday.com',

      // Required only when using Realtime.
      HosteDayOptionKeys.realtimeHost: 'ws3.hosteday.com',
      HosteDayOptionKeys.pusherKey: 'YOUR_PUSHER_KEY',
    },
  );

  runApp(const App());
}
```

`project_domain` is required.

`realtime_host` is optional when Realtime uses the same domain as the API project. If omitted,
HosteDay uses the host from `project_domain` or `api_base_url`.

You do not need to pass these values unless your server requires different settings:

```text
realtime_scheme = wss
realtime_port   = 443
```

---

## Core API

The official SDK entry point is:

```dart
HosteDay
```

Use these accessors after initialization:

```dart
HosteDay.instance
HosteDay.client
HosteDay.config
HosteDay.auth
```

Example:

```dart

final client = HosteDay.client;
final auth = HosteDay.auth;
final config = HosteDay.config;
```

> `Hosteday` remains available as a deprecated compatibility alias. Use `HosteDay` in all new
> projects.

---

## Authentication

`HosteDayAuth` provides a Firebase-inspired authentication API.

```dart
HosteDay.auth
```

Available accessors:

```dart
HosteDay.auth.currentUser
HosteDay.auth.currentSession
HosteDay.auth.getAccessToken
()
```

Available state streams:

```dart
HosteDay.auth.authStateChanges
()
HosteDay.auth.idTokenChanges
()
HosteDay.auth.userChanges
()
```

---

## Authentication Gate

Use `authStateChanges()` to switch between signed-in and signed-out screens.

```dart
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HosteDayUser?>(
      stream: HosteDay.auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginPage();
        }

        return HomePage(user: user);
      },
    );
  }
}
```

The stream emits the current user immediately, then emits future sign-in and sign-out changes.

---

## Sign In

```dart

final credential = await
HosteDay.auth.signInWithEmailAndPassword
(
email: 'user@example.com',
password: 'password',
);

final user = credential.user;
final session = credential.session;

print(user.id);
print(user.email);
print
(
session
.
accessToken
);
```

After successful sign-in, HosteDay automatically:

1. Stores the authenticated session.
2. Stores the access token.
3. Updates `currentUser`.
4. Emits authentication state changes.
5. Uses the new token for protected requests.
6. Uses the new token when authorizing private Realtime channels.

---

## Register

```dart

final credential = await
HosteDay.auth.createUserWithEmailAndPassword
(
email: 'new-user@example.com',
password: 'password',
additionalData: <String, dynamic>{
'name': 'Mustafa',
},
);

print(credential.user.displayName);
```

`additionalData` can include backend-specific fields such as:

```dart
additionalData: <
String, dynamic>{
'name': 'Mustafa',
'phone': '+964...',
'tenant_id': 1,
}
```

The SDK automatically adds:

```text
email
password
password_confirmation
```

---

## Current User

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
}
```

---

## Reload User Data

Reload the current user from the configured user endpoint:

```dart

final user = await
HosteDay.auth.reload
();

print
(
user.displayName);
print(user.emailVerified);
```

The default endpoint is:

```text
GET /api/user
```

---

## Update Profile

```dart

final user = await
HosteDay.auth.updateProfile
(<String, dynamic>{
'name': 'Mustafa Max',
'email': 'mustafa@example.com',
},
);

print(user.displayName);
```

The default endpoint is:

```text
PUT /api/user
```

The supported fields depend on your Laravel backend.

---

## Email Verification

Request an email verification message for the signed-in user:

```dart
await
HosteDay.auth.sendEmailVerification
();
```

The default endpoint is:

```text
POST /api/email/verify
```

---

## Password Reset

### Send Password Reset Email

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

The default endpoint is:

```text
POST /api/auth/forgot-password
```

### Confirm Password Reset

```dart
await
HosteDay.auth.confirmPasswordReset
(
email: 'user@example.com',
token: 'RESET_TOKEN',
newPassword
:
'
new-password
'
,
);
```

The default endpoint is:

```text
POST /api/auth/reset-password
```

---

## Sign Out

```dart
await
HosteDay.auth.signOut
();
```

When signing out, HosteDay:

1. Attempts to call the configured logout endpoint.
2. Removes the local session and access token.
3. Sets `currentUser` to `null`.
4. Emits `null` through authentication streams.
5. Disconnects Realtime to prevent private subscriptions from remaining active.

The default endpoint is:

```text
POST /api/logout
```

The local session is removed even if the remote logout endpoint fails.

---

## Session Storage

By default, HosteDay uses `MemoryHosteDayAuthStorage`.

This is useful for tests and quick examples, but the session will be lost when the application
closes.

For production applications, provide a persistent secure implementation of `HosteDayAuthStorage`.

Example using `flutter_secure_storage` in your Flutter application:

```bash
flutter pub add flutter_secure_storage
```

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

class SecureHosteDayAuthStorage implements HosteDayAuthStorage {
  const SecureHosteDayAuthStorage(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  @override
  Future<void> write(String key, String value) {
    return _storage.write(
      key: key,
      value: value,
    );
  }

  @override
  Future<void> delete(String key) {
    return _storage.delete(key: key);
  }
}
```

Use it during initialization:

```dart
await
HosteDay.initializeApp
(
options: const <String, Object?>{
HosteDayOptionKeys.projectDomain: 'your-project.hosteday.com',
},
authStorage: SecureHosteDayAuthStorage(
FlutterSecureStorage(),
),
);
```

> Never store production access tokens in plain text storage.

---

## Protected API Requests

After sign-in, use `withAuth: true` for protected requests.

```dart

final response = await
HosteDay.client.get
('/api/posts
'
,withAuth: true,
);

print(response);
```

The active access token is automatically added as:

```http
Authorization: Bearer YOUR_ACCESS_TOKEN
```

You do not need to extract, store, or pass the user token manually after calling
`HosteDay.auth.signInWithEmailAndPassword(...)`.

---

## HTTP Requests

Use `HosteDay.client` for custom API requests.

```dart

final response = await
HosteDay.client.get
('/api/items
'
);

print(
response
);
```

All successful requests return decoded JSON as:

```dart
Map<String, dynamic>
```

### GET

```dart

final response = await
HosteDay.client.get
('/api/items
'
,withAuth:
true
,
);
```

### POST

```dart

final response = await
HosteDay.client.post
('/api/items
'
,withAuth: true,
body: <String, dynamic>{
'title': 'New item',
'description': 'Item description',
},
);
```

### PUT

```dart

final response = await
HosteDay.client.put
('/api/items/1
'
,withAuth: true,
body: <String, dynamic>{
'title': 'Updated item',
},
);
```

### PATCH

```dart

final response = await
HosteDay.client.patch
('/api/items/1
'
,withAuth: true,
body: <String, dynamic>{
'status': 'published',
},
);
```

### DELETE

```dart

final response = await
HosteDay.client.delete
('/api/items/1
'
,withAuth:
true
,
);
```

---

## Project API Token

Some HosteDay projects may require a project-level API token through the `X-Api-Token` header.

Configure it during initialization:

```dart
await
HosteDay.initializeApp
(
options: const <String, Object?>{
HosteDayOptionKeys.projectDomain: 'your-project.hosteday.com',
HosteDayOptionKeys.apiToken: 'PROJECT_API_TOKEN',
},
);
```

The SDK includes this header automatically in all HTTP requests:

```http
X-Api-Token: PROJECT_API_TOKEN
```

A project API token and a user bearer token can be used together.

---

## Realtime

HosteDay supports Pusher-compatible Realtime services through `HosteDay.client.realtime`.

Initialize Realtime settings once:

```dart
await
HosteDay.initializeApp
(
options: const <String, Object?>{
HosteDayOptionKeys.projectDomain: 'your-project.hosteday.com',
HosteDayOptionKeys.realtimeHost: 'ws3.hosteday.com',
HosteDayOptionKeys.pusherKey: 'YOUR_PUSHER_KEY',
},
);
```

Connect when Realtime is needed:

```dart
await
HosteDay.connectRealtime
();
```

You can inspect the generated endpoint:

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
wss://ws3.hosteday.com:443/app/YOUR_PUSHER_KEY
```

---

## Public Channel

Public channels do not require user authentication.

```dart
await
HosteDay.connectRealtime
();

final subscription = await
HosteDay.client.realtime.listenPublic
(
channel: 'tenant.chat.room.1',
event: 'message.sent',
onEvent: (event) {
print(event.name);
print(event.channelName);
print(event.payload);
print(event.message);
},
);
```

---

## Private Channel

Private channels require a signed-in user.

```dart
await
HosteDay.connectRealtime
();

final subscription = await
HosteDay.client.realtime.listenPrivate
(
channel: 'tenant.chat.room.1',
event: 'message.sent',
onEvent: (event) {
print(event.message);
print(event.userId);
print(event.userName);
print(event.userEmail);
},
);
```

The SDK automatically adds the `private-` prefix when it is missing.

The current HosteDay authentication token is automatically included while authorizing the channel.

---

## Presence Channel

Presence channels require a signed-in user and can track connected members.

```dart
await
HosteDay.connectRealtime
();

await
HosteDay.client.realtime.listenPresence
(
channel: 'tenant.chat.room.1',
event: 'message.sent',
onEvent: (event) {
print(event.payload);
},
);

await HosteDay.client.realtime.listenPresenceMemberAdded(
channel: 'tenant.chat.room.1',
onEvent: (event) {
print('Member joined: ${event.payload}');
},
);

await HosteDay.client.realtime.listenPresenceMemberRemoved(
channel: 'tenant.chat.room.1',
onEvent: (event) {
print('Member left: ${event.payload}');
},
);
```

The SDK automatically adds the `presence-` prefix when it is missing.

---

## Unified Realtime Listener

Use the unified `listen(...)` method when you need to select the channel type dynamically.

```dart

final subscription = await
HosteDay.client.realtime.listen
(
channel: 'tenant.chat.room.1',
event: 'message.sent',
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

## Publish Realtime Events

### Public Event

```dart

final response = await
HosteDay.client.publishPublicEvent
(
channel: 'tenant.chat.room.1',
event: 'message.sent',
payload: <String, dynamic>{
'message': 'Hello from Flutter',
},
);

print
(
response
);
```

### Private Event

Private event publishing requires an authenticated user.

```dart

final response = await
HosteDay.client.publishPrivateEvent
(
channel: 'private-tenant.chat.room.1',
event: 'message.sent',
payload: <String, dynamic>{
'message': 'Private message',
},
);

print
(
response
);
```

### Presence Event

```dart

final response = await
HosteDay.client.publishPresenceEvent
(
channel: 'tenant.chat.room.1',
event: 'member.typing',
payload: <String, dynamic>{
'typing': true,
},
);

print
(
response
);
```

`publishPresenceEvent(...)` automatically adds the `presence-` prefix when needed.

---

## Unsubscribe and Disconnect

Unsubscribe from a channel without closing the WebSocket connection:

```dart
await
HosteDay.client.realtime.unsubscribe
('tenant.chat.room.1
'
,type:
HosteDayChannelType
.
private
,
);
```

Disconnect all Realtime channels and close the WebSocket connection:

```dart
await
HosteDay.client.realtime.disconnect
();
```

Release the full SDK when your application no longer needs it:

```dart
await
HosteDay.dispose
();
```

---

## Configuration

HosteDay uses `HosteDayConfig` internally.

The SDK configuration is created through:

```dart
HosteDay.initializeApp
(
options: {
// HosteDay options.
},
);
```

### Core Options

| Option key        | Required      | Description                                                   |
|-------------------|---------------|---------------------------------------------------------------|
| `project_domain`  | Yes           | Your HosteDay project domain, such as `example.hosteday.com`. |
| `api_base_url`    | No            | Overrides the API base URL.                                   |
| `base_url`        | No            | Alternative key for overriding the API base URL.              |
| `X-Api-Token`     | No            | Project-level API token sent with all requests.               |
| `pusher_key`      | Realtime only | Pusher-compatible application key.                            |
| `realtime_host`   | No            | Realtime server host. Defaults to the API host.               |
| `realtime_scheme` | No            | Defaults to `wss`.                                            |
| `realtime_port`   | No            | Defaults to `443`.                                            |

### Path Override Options

| Option key                     | Default value                   |
|--------------------------------|---------------------------------|
| `login_path_post`              | `/api/auth/login`               |
| `register_path_post`           | `/api/auth/register`            |
| `forgot_password_path_post`    | `/api/auth/forgot-password`     |
| `reset_password_path_post`     | `/api/auth/reset-password`      |
| `user_show_path_get`           | `/api/user`                     |
| `user_update_path_put`         | `/api/user`                     |
| `user_update_avatar_path_post` | `/api/user/avatar`              |
| `user_delete_path_delete`      | `/api/user`                     |
| `logout_path_post`             | `/api/logout`                   |
| `email_verify_path_post`       | `/api/email/verify`             |
| `public_events_path`           | `/api/realtime/events/public`   |
| `private_events_path`          | `/api/realtime/events/private`  |
| `presence_events_path`         | `/api/realtime/events/presence` |
| `broadcasting_auth_path`       | `/api/broadcasting/auth-manual` |

Example with custom paths:

```dart
await
HosteDay.initializeApp
(
options: const <String, Object?>{
HosteDayOptionKeys.projectDomain: 'your-project.hosteday.com',
'login_path_post': '/api/v1/auth/login',
'user_show_path_get': '/api/v1/me',
'broadcasting_auth_path': '/api/v1/broadcasting/auth',
},
);
```

---

## Backend Authentication Response

The login and register endpoints must return a user and an access token.

Recommended Laravel response:

```json
{
  "access_token": "1|example-token",
  "token_type": "Bearer",
  "expires_in": null,
  "user": {
    "id": 1,
    "name": "Mustafa",
    "email": "mustafa@example.com",
    "email_verified": true,
    "avatar_url": null
  }
}
```

The SDK also accepts common alternatives:

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

Or:

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

Supported access-token keys:

```text
access_token
accessToken
token
```

Supported user identifiers:

```text
id
user_id
uuid
```

---

## Error Handling

All network and API failures are reported through `HosteDayException`.

Authentication failures are reported through `HosteDayAuthException`.

```dart
try {
final credential = await HosteDay.auth.signInWithEmailAndPassword(
email: 'user@example.com',
password: 'password',
);

print(credential.user.email);
} on HosteDayAuthException catch (error) {
print(error.code);
print(error.message);
print(error.statusCode);
print(error.error);
} on HosteDayException catch (error) {
print(error.message);
print(error.statusCode);
print(error.error);
} catch (error) {
print(error);
}
```

Typical authentication error codes include:

```text
invalid-email
wrong-password
invalid-credentials
email-already-in-use
validation-failed
permission-denied
no-current-user
malformed-auth-response
auth-request-failed
```

---

## Migration from `Hosteday`

The old entry point is deprecated:

```dart
Hosteday.initializeApp
(...)Hosteday.
client
Hosteday
.
config
```

Use the new official API:

```dart
HosteDay.initializeApp
(...)HosteDay.
client
HosteDay
.
config
HosteDay
.
auth
```

### Before

```dart

final tokenProvider = StaticHosteDayTokenProvider(
  'USER_TOKEN_HERE',
);

await
Hosteday.initializeApp
(
options: {
'project_domain': 'example.hosteday.com',
},
tokenProvider: tokenProvider,
);

final response = await Hosteday.client.post(
Hosteday.config.loginPathPost,
body: {
'email': email,
'password': password,
},
);
```

### After

```dart
await
HosteDay.initializeApp
(
options: {
'project_domain': 'example.hosteday.com',
},
);

final credential = await HosteDay.auth.signInWithEmailAndPassword(
email: email,
password: password,
);

final response = await HosteDay.client.get(
'/api/user',
withAuth: true,
);

print(credential.user.email);
print
(
response
);
```

The access token is now stored and retrieved internally by HosteDay.

---

## Example Application

A complete Flutter example is included in this repository:

[Open the example application](example/lib/main.dart)

The example demonstrates:

* Authentication gate.
* Sign in and registration.
* Session-aware API requests.
* Current user reload and update.
* Password reset requests.
* Email verification requests.
* Public, private, and presence Realtime channels.
* Publishing and receiving Realtime events.
* Automatic session cleanup on sign out.

---

## Security Notes

* Never hard-code production user tokens in source code.
* Use a secure `HosteDayAuthStorage` implementation in production.
* Keep project API tokens out of public repositories.
* Validate authorization and tenant ownership in your Laravel backend.
* Do not trust client-side checks as a replacement for server-side authorization.
* Use protected Realtime channel authorization for sensitive events.
* Revoke or invalidate tokens server-side when your security model requires it.

---

## License

This project is licensed under the [MIT License](LICENSE).
