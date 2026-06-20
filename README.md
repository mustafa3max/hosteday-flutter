# HosteDay Flutter

[![pub package](https://img.shields.io/pub/v/hosteday_flutter.svg)](https://pub.dev/packages/hosteday_flutter)
[![platform](https://img.shields.io/badge/platform-Flutter-blue.svg)](https://flutter.dev)
[![license](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A Flutter and Dart client for connecting applications to HosteDay APIs.

Use `hosteday_flutter` to communicate with your HosteDay backend through a single client for authentication, user management, custom API requests, and real-time events.

![Flutter Example App](https://raw.githubusercontent.com/mustafa3max/hosteday-flutter/master/assets/flutter-example.png)

## Features

* Unified HTTP client for `GET`, `POST`, `PUT`, `PATCH`, and `DELETE` requests.
* Configurable default paths for authentication and user management.
* Optional token provider for authenticated API requests.
* Support for custom request headers, including `X-Api-Token`.
* Public and private Pusher-compatible real-time channels.
* Structured `HosteDayException` errors for API and network failures.
* Custom endpoint support for any route in your HosteDay backend.

## Installation

Add the package to your Flutter project:

```bash
flutter pub add hosteday_flutter
```

Then import it:

```dart
import 'package:hosteday_flutter/hosteday_flutter.dart';
```

## Quick Start

Create one `HosteDayClient` instance during application startup:

```dart
import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

late final HosteDayClient hosteday;

void main() {
  hosteday = HosteDayClient(
    config: const HosteDayConfig(
      baseUrl: 'https://your-project.hosteday.com',
    ),
  );

  runApp(const App());
}
```

Replace `https://your-project.hosteday.com` with the URL of your HosteDay project.

## Basic Request

Use the client methods to send requests to your backend:

```dart
final response = await hosteday.get('/api/items');

print(response);
```

Every successful request returns a `Map<String, dynamic>` containing the decoded JSON response.

## Configuration

`HosteDayConfig` contains the project URL, real-time settings, and the default API paths used by the package.

```dart
const config = HosteDayConfig(
  baseUrl: 'https://your-project.hosteday.com',
  pusherKey: 'YOUR_PUSHER_KEY',
  realtimeHost: 'your-project.hosteday.com',
  realtimePort: 443,
);
```

The final request URL is built from:

```text
baseUrl + path
```

For example:

```text
https://your-project.hosteday.com/api/auth/login
```

### Custom Paths

You can override any default endpoint path when creating the configuration:

```dart
const config = HosteDayConfig(
  baseUrl: 'https://your-project.hosteday.com',
  loginPathPost: '/api/v1/login',
  userShowPathGet: '/api/v1/me',
);
```

## Default API Paths

### Authentication

| Purpose         | Method | Config property          | Default path                |
| --------------- | -----: | ------------------------ | --------------------------- |
| Login           | `POST` | `loginPathPost`          | `/api/auth/login`           |
| Register        | `POST` | `registerPathPost`       | `/api/auth/register`        |
| Forgot password | `POST` | `forgotPasswordPathPost` | `/api/auth/forgot-password` |
| Reset password  | `POST` | `resetPasswordPathPost`  | `/api/auth/reset-password`  |

### User Management

| Purpose                |   Method | Config property            | Default path        |
| ---------------------- | -------: | -------------------------- | ------------------- |
| Get authenticated user |    `GET` | `userShowPathGet`          | `/api/user`         |
| Update user            |    `PUT` | `userUpdatePathPut`        | `/api/user`         |
| Update avatar          |   `POST` | `userUpdateAvatarPathPost` | `/api/user/avatar`  |
| Delete user            | `DELETE` | `userDeletePathDelete`     | `/api/user`         |
| Logout                 |   `POST` | `logoutPathPost`           | `/api/logout`       |
| Verify email           |   `POST` | `emailVerifyPathPost`      | `/api/email/verify` |

### Real-Time

| Purpose                   | Method | Config property        | Default path                    |
| ------------------------- | -----: | ---------------------- | ------------------------------- |
| Publish public event      | `POST` | `publicEventsPath`     | `/api/realtime/events`          |
| Publish private event     | `POST` | `privateEventsPath`    | `/api/realtime/private-events`  |
| Authorize private channel | `POST` | `broadcastingAuthPath` | `/api/broadcasting/auth-manual` |

## Authentication

### Login

```dart
final response = await hosteday.post(
hosteday.config.loginPathPost,
body: {
'email': 'user@example.com',
'password': 'password',
},
);

print(response);
```

Example response:

```json
{
  "token": "USER_TOKEN_HERE",
  "user": {
    "id": 1,
    "name": "Mustafa",
    "email": "user@example.com"
  }
}
```

### Register

```dart
final response = await hosteday.post(
hosteday.config.registerPathPost,
body: {
'name': 'Mustafa',
'email': 'user@example.com',
'password': 'password',
},
);

print(response);
```

### Forgot Password

```dart
final response = await hosteday.post(
hosteday.config.forgotPasswordPathPost,
body: {
'email': 'user@example.com',
},
);

print(response);
```

### Reset Password

```dart
final response = await hosteday.post(
hosteday.config.resetPasswordPathPost,
body: {
'email': 'user@example.com',
'token': 'RESET_TOKEN',
'password': 'new-password',
},
);

print(response);
```

## Token Provider

For protected routes, configure a `HosteDayTokenProvider`. This lets the package attach the bearer token automatically whenever `withAuth` is set to `true`.

```dart
final hosteday = HosteDayClient(
  config: const HosteDayConfig(
    baseUrl: 'https://your-project.hosteday.com',
  ),
  tokenProvider: const StaticHosteDayTokenProvider(
    'USER_TOKEN_HERE',
  ),
);
```

For production apps, implement `HosteDayTokenProvider` and retrieve the token from secure storage:

```dart
class AppTokenProvider implements HosteDayTokenProvider {
  const AppTokenProvider();

  @override
  Future<String?> getToken() async {
    // Read and return the saved token from your secure storage solution.
    return null;
  }
}
```

Use `withAuth: true` for protected routes:

```dart
final response = await hosteday.get(
hosteday.config.userShowPathGet,
withAuth: true,
);

print(response);
```

## Manual Authorization Header

You can also pass the authorization header manually:

```dart
final response = await hosteday.get(
hosteday.config.userShowPathGet,
headers: {
'Authorization': 'Bearer USER_TOKEN_HERE',
},
);

print(response);
```

## Link Protection With `X-Api-Token`

Some HosteDay projects may use Link Protection. In this case, requests can require both the user token and the project API token.

```dart
final response = await hosteday.get(
hosteday.config.userShowPathGet,
withAuth: true,
headers: {
'X-Api-Token': 'PROJECT_API_TOKEN_HERE',
},
);

print(response);
```

The same header can be supplied with `POST`, `PUT`, `PATCH`, and `DELETE` requests.

> Do not place real production tokens in source code or public repositories. Store sensitive values securely and load them through environment configuration or secure storage.

## User Management

### Get User

```dart
final response = await hosteday.get(
hosteday.config.userShowPathGet,
withAuth: true,
);

print(response);
```

### Update User

```dart
final response = await hosteday.put(
hosteday.config.userUpdatePathPut,
withAuth: true,
body: {
'name': 'Mustafa',
'email': 'user@example.com',
'password': 'new-password',
},
);

print(response);
```

### Update User Avatar

```dart
final response = await hosteday.post(
hosteday.config.userUpdateAvatarPathPost,
withAuth: true,
body: {
'avatar': 'AVATAR_VALUE',
},
);

print(response);
```

### Logout

```dart
final response = await hosteday.post(
hosteday.config.logoutPathPost,
withAuth: true,
);

print(response);
```

### Delete User

```dart
final response = await hosteday.delete(
hosteday.config.userDeletePathDelete,
withAuth: true,
);

print(response);
```

### Email Verification

```dart
final response = await hosteday.post(
hosteday.config.emailVerifyPathPost,
withAuth: true,
body: {
'code': '123456',
},
);

print(response);
```

## Custom API Requests

Use any custom endpoint exposed by your HosteDay backend:

```dart
final response = await hosteday.post(
'/api/items',
withAuth: true,
body: {
'title': 'New Item',
'description': 'Item description',
},
);

print(response);
```

## Supported HTTP Methods

```dart
await hosteday.get('/api/items');

await hosteday.post(
'/api/items',
body: {
'title': 'New item',
},
);

await hosteday.put(
'/api/items/1',
body: {
'title': 'Updated item',
},
);

await hosteday.patch(
'/api/items/1',
body: {
'status': 'published',
},
);

await hosteday.delete('/api/items/1');
```

## Real-Time Events

Configure the real-time connection when creating `HosteDayConfig`:

```dart
final hosteday = HosteDayClient(
  config: const HosteDayConfig(
    baseUrl: 'https://your-project.hosteday.com',
    pusherKey: 'YOUR_PUSHER_KEY',
    realtimeHost: 'your-project.hosteday.com',
    realtimePort: 443,
  ),
  tokenProvider: const StaticHosteDayTokenProvider(
    'USER_TOKEN_HERE',
  ),
);
```

Connect before subscribing to channels:

```dart
await hosteday.realtime.connect();
```

### Listen to a Public Channel

```dart
final subscription = hosteday.realtime.listenPublic(
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

### Listen to a Private Channel

```dart
final subscription = await hosteday.realtime.listenPrivate(
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

The private channel name is automatically prefixed with `private-` when necessary.

### Disconnect

Release real-time and HTTP resources when the client is no longer needed:

```dart
await hosteday.dispose();
```

## Error Handling

All HosteDay API and network failures are reported as `HosteDayException`.

```dart
try {
final response = await hosteday.get(
hosteday.config.userShowPathGet,
withAuth: true,
);

print(response);
} on HosteDayException catch (error) {
print(error.message);
print(error.statusCode);
print(error.error);
} catch (error) {
print(error);
}
```

## Example Application

A complete Flutter example is included in this repository:

[Open the example application](example/lib/main.dart)

## Learn More

Build your Flutter application with a consistent connection to HosteDay APIs, authentication, and real-time events. Visit the [HosteDay for Flutter page](https://hosteday.com/flutter) for an overview of the Flutter integration and recommended workflow.

For information about the HosteDay platform, project setup, and API infrastructure, visit the [HosteDay website](https://hosteday.com/).

## Notes

* Replace `https://your-project.hosteday.com` with your actual HosteDay project URL.
* Initialize `HosteDayClient` once and reuse it across your application.
* Use `withAuth: true` together with a token provider for protected routes.
* Pass custom headers when your project requires additional API protection.
* Call `await hosteday.realtime.connect()` before listening to channels.
* Call `await hosteday.dispose()` when the client is no longer needed.
* Do not hard-code production tokens in public source code.

## License

This project is licensed under the [MIT License](LICENSE).

```
```
