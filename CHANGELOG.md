# Changelog

All notable changes to `hosteday_flutter` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
follows Semantic Versioning.

## [1.0.6] - 2026-07-01

### Added

* Added a runnable Flutter example application in `example/lib/main.dart`.
* Added a simple authentication interface for:

    * Sign in with email and password.
    * Create a new account.
    * Automatic navigation based on `authStateChanges()`.
    * Sign out.
* Added support for passing example configuration through Dart environment variables:

    * `HOSTEDAY_PROJECT_DOMAIN`
    * `HOSTEDAY_API_TOKEN`

### Changed

* Updated the example application to use `HosteDay.initializeApp(...)`.
* Updated the example to use `HosteDay.auth.signInWithEmailAndPassword(...)`.
* Updated the example to use `HosteDay.auth.createUserWithEmailAndPassword(...)`.
* Removed hard-coded project API tokens from the published example source code.

### Security

* Project API tokens should now be provided through `--dart-define` when running the example.
* Do not commit production API tokens or user access tokens to public repositories.

## [1.0.5] - 2026-06-22

### Added

- Added a Firebase-inspired authentication layer through `HosteDayAuth`.
- Added `HosteDayUser`, `HosteDaySession`, and `HosteDayUserCredential`.
- Added `HosteDayAuthException` for authentication-specific failures.
- Added `HosteDayAuthStorage` and `MemoryHosteDayAuthStorage`.
- Added automatic session restoration during SDK initialization.
- Added automatic access-token handling for authenticated HTTP requests and private Realtime
  channels.
- Added authentication state streams:
    - `authStateChanges()`
    - `idTokenChanges()`
    - `userChanges()`
- Added authentication methods:
    - `signInWithEmailAndPassword(...)`
    - `createUserWithEmailAndPassword(...)`
    - `signOut()`
    - `sendPasswordResetEmail(...)`
    - `confirmPasswordReset(...)`
    - `reload()`
    - `updateProfile(...)`
    - `sendEmailVerification()`
- Added HTTP convenience methods to `HosteDayHttpClient`:
    - `get(...)`
    - `post(...)`
    - `put(...)`
    - `patch(...)`
    - `delete(...)`
- Added `HosteDayConfig.realtimeUrl`.

### Changed

- Renamed the official SDK entry point from `Hosteday` to `HosteDay`.
- Added `HosteDay.auth` as the central authentication API.
- Updated `HosteDayClient` to manage auth, HTTP, and Realtime through a shared dynamic token
  provider.
- Protected requests using `withAuth: true` now automatically use the active authenticated session
  token.
- Private, presence, and private encrypted channels now automatically use the current authentication
  session token.
- SDK initialization now restores the persisted local session before returning.
- Realtime now uses `wss` and port `443` by default when no custom values are supplied.
- Added `HosteDay.config.realtimeUrl` for the complete WebSocket endpoint.

### Deprecated

- Deprecated `Hosteday`.
- Use `HosteDay.initializeApp(...)`, `HosteDay.client`, `HosteDay.config`, and `HosteDay.auth` in
  all new projects.
- Manual token extraction and manual bearer-token state management are no longer recommended after
  using `HosteDayAuth`.

### Fixed

- Fixed missing `get`, `post`, `put`, `patch`, and `delete` methods in `HosteDayHttpClient`.
- Fixed token synchronization between authenticated API requests and Realtime channel authorization.
- Fixed local session cleanup when remote logout fails.

### Migration Guide

#### Before

```dart

final tokenProvider = StaticHosteDayTokenProvider(token);

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

final token = response['token'];

await Hosteday.client.get(
'/api/user',
withAuth: true,
);
```

#### After

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

final user = credential.user;

final response = await HosteDay.client.get(
'/api/user',
withAuth: true,
);
```

The authenticated access token is now stored and used internally by the SDK.

#### Authentication State

```dart
HosteDay.auth.authStateChanges
().listen
(
(user) {
if (user == null) {
print('Signed out');
return;
}

print('Signed in as ${user.email}');
});
```

#### Private Realtime Channel

```dart
await
HosteDay.connectRealtime
();

await
HosteDay.client.realtime.listenPrivate
(
channel: 'tenant.chat.room.1',
event: 'message.sent',
onEvent: (event) {
print(event.payload);
},
);
```

No manual Bearer token handling is required after successful sign-in.

### Backend Response Requirements

The login and registration endpoints should return a session response containing a user and access
token.

Recommended response format:

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

The SDK also supports common alternative response shapes such as:

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

or:

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

### Notes

* `MemoryHosteDayAuthStorage` is suitable only for tests, demos, and temporary sessions.
* Production applications should provide an implementation of `HosteDayAuthStorage` backed by secure
  persistent storage.
* A future release may provide an official secure storage adapter for Flutter.
* `Hosteday` will be removed in a future major release. Use `HosteDay` in all new projects.
