# Hosteday API reference

See the [README](../README.md) for initialization, CRUD, runtime assets, URLs,
pagination, project keys, and errors. This reference covers the remaining public API.

## Application lifecycle

`Hosteday.isInitialized` and `Hosteday.isInitializing` report SDK lifecycle state.
`client` and `instance` return the same client. `config`, `auth`, `http`, and
`realtime` expose its services. Initialize once; dispose before switching projects.

For independent clients and transport testing:

```dart
final client = HostedayClient(
  config: HostedayConfig.fromOptions({'project_domain': 'max.hosteday.com'}),
  httpClient: customHttpClient,
  authStorage: MemoryHostedayAuthStorage(),
);
await client.initialize();
final response = await client.get('/products');
await client.dispose();
```

The SDK closes an injected HTTP client on disposal. Do not share an owned
transport between independently disposed clients.

## Profile and avatar

```dart
final user = await Hosteday.auth.updateProfile(name: 'Customer');
await Hosteday.auth.updateAvatar(bytes: imageBytes, extension: 'png');
await Hosteday.auth.sendCurrentUserPasswordResetEmail();
await Hosteday.auth.sendEmailVerification();
```

`imageBytes` is `Uint8List`. Supported extensions: jpg, jpeg, png, webp.
The SDK sends Base64 JSON to the fixed avatar endpoint and refreshes the session.
Profile updates use `PUT /api/user`, without a fabricated resource ID.
Password resets and email verification are completed through the server's email link.

```dart
await Hosteday.auth.deleteUser();
```

Account deletion clears the local session after server success. `signOut()` clears
the local session even when the remote logout fails, then reports that failure.

## User and session models

`HostedayUser` exposes `id`, `email`, `displayName`, `photoUrl`,
`emailVerified`, `data`, `fromJson`, `toJson`, and `copyWith`.
`user[key]` accesses additional fields; `name` and `avatarUrl` are convenience aliases.
`HostedayUserCredential` contains `user`, `session`, and `isNewUser`.
`HostedaySession` stores the access token and associated user, with JSON persistence.

```dart
final current = Hosteday.auth.currentUser;
final session = Hosteday.auth.currentSession;
final token = await Hosteday.auth.getAccessToken();
final subscription = Hosteday.auth.userChanges().listen((user) {
  // Update application state with the actual user, or null after sign-out.
});
await subscription.cancel();
```

`authStateChanges()` observes sign-in/out, `idTokenChanges()` observes token state,
and `userChanges()` also covers profile changes. Streams include current state.

## Storage and external tokens

Implement `HostedayAuthStorage.read`, `write`, and `delete` with asynchronous
string storage. Existing session keys remain unchanged for installed applications.
`MemoryHostedayAuthStorage` lasts for one process. The SharedPreferences adapter
persists data without encryption.

```dart
class AppTokenProvider implements HostedayTokenProvider {
  final Future<String?> Function() readToken;
  AppTokenProvider(this.readToken);
  @override
  Future<String?> getToken() => readToken();
}
```

Pass it as `tokenProvider` during initialization. The SDK session token takes
precedence; this provider is a fallback. `StaticHostedayTokenProvider(token)`
is available for a token already held by the application.

## Realtime subscriptions

Configure both `realtime_app_key` and `realtime_host`, then connect explicitly.
The defaults are WSS on port 443; WS defaults to port 80 when parsed from options.

```dart
await Hosteday.connectRealtime();
final subscription = await Hosteday.realtime.listenPublic(
  channel: 'products',
  event: 'updated',
  onEvent: (event) {
    final payload = event.payload;
    // Apply the server event to application state.
  },
);
await subscription.cancel();
await Hosteday.realtime.unsubscribe('products');
await Hosteday.disconnectRealtime();
```

`listenPrivate`, `listenPresence`, and `listenPrivateEncrypted` have the same
named channel/event/onEvent arguments and require a user token. The unified
`listen` additionally accepts `type: HostedayChannelType.private` (or public,
presence, privateEncrypted). Channel names are normalized by the SDK.

`publicChannel`, `privateChannel`, `presenceChannel`, `privateEncryptedChannel`,
and `channel` expose the underlying Pusher-compatible channels. `getChannel`
looks up a tracked channel. Presence membership is observable through
`listenPresenceMemberAdded` and `listenPresenceMemberRemoved`.

`HostedayRealtimeEvent` provides `name`, `channelName`, `payload`, `raw`, `data`,
`toJson`, and indexed payload access, plus `message`, `id`, `title`, `type`,
`user`, `userId`, `userName`, and `userEmail` helpers.

`isConnected` retains the existing meaning of an allocated connection client;
it is not a server acknowledgement or a network-health guarantee.

## Exceptions

`HostedayException` retains `message`, `statusCode`, `validationErrors`, `response`,
and `error`. Helpers include `isValidationError`, `isUnauthenticated`,
`isForbidden`, `isNotFound`, `isServerError`, `hasValidationErrors`,
`firstErrorFor`, `firstValidationError`, and `displayMessage`.
`HostedayAuthException` adds a machine-readable `code` and preserves the same details.

```dart
try {
  await Hosteday.auth.signInWithEmailAndPassword(email: email, password: password);
} on HostedayAuthException catch (error) {
  final fieldError = error.firstErrorFor('email');
  final code = error.code;
}
```

## Fixed service routes

These paths are platform contracts and remain internal to the SDK.

| Operation | Route |
| --- | --- |
| Sign in / register | `/api/auth/login`, `/api/auth/register` |
| Password reset email | `/api/auth/forgot-password` |
| Current user / profile / delete | `/api/user` |
| Avatar | `/api/user/avatar` |
| Current user's password reset email | `/api/user/password-reset-email` |
| Sign out | `/api/logout` |
| Verification notification | `/api/email/verification-notification` |
| Realtime publishing | `/api/realtime/events/public`, `/private`, `/presence` |
| Private channel authorization | `/api/broadcasting/auth-manual` |

Old option constants for overriding fixed route paths remain source-compatible,
but `fromOptions` does not consume them. Resource calls use normal relative paths.
