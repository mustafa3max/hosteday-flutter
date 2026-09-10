# hosteday_flutter

Flutter SDK for Hosteday REST, authentication, public URLs, and optional Realtime.

## Installation

This archive contains the unreleased 2.2.0 source. Until you publish it, use a local
`path: /path/to/hosteday-flutter` dependency (as the bundled example does). After publication:

```yaml
dependencies:
  hosteday_flutter: ^2.2.0
```

```dart
import 'package:hosteday_flutter/hosteday_flutter.dart';
```

## Initialize Hosteday

Only the project domain is required. No network request is made by the default initialization.

```dart
await Hosteday.initializeApp(options: {
  HostedayOptionKeys.projectDomain: 'max.hosteday.com',
});
```

Optional values may be null. `http://localhost:8787` preserves HTTP and the port.
Call `await Hosteday.dispose()` before switching projects.

### Generated app runtime config

Declare the asset in the application's `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/config/hosteday.json
```

```json
{
  "project_domain": "max.hosteday.com",
  "project_api_key": null,
  "realtime_app_key": null,
  "realtime_host": null
}
```

```dart
WidgetsFlutterBinding.ensureInitialized();
await Hosteday.initializeFromAsset();
```

`initializeFromAsset(overrides: {...})` supports explicit option overrides.
The engine only needs to supply the asset and ordinary SDK resource calls.

## REST API

Relative resource paths automatically receive `/api`. `products`, `/products`,
and `/api/products` all target `https://max.hosteday.com/api/products`.

### GET

```dart
final products = await Hosteday.client.get('/products');
final product = await Hosteday.client.get('/products', id: 15);
```

### POST

```dart
final created = await Hosteday.client.post('/products',
  body: {'name': 'Phone', 'price': 250},
  withAuth: true,
);
```

### PUT

```dart
await Hosteday.client.put('/products', id: 15,
  body: {'name': 'Phone', 'price': 240},
);
```

### PATCH

```dart
await Hosteday.client.patch('/products/15', body: {'price': 230});
```

### DELETE

```dart
await Hosteday.client.delete('/products', id: 15);
```

`id` is optional for PUT/PATCH/DELETE when it is already part of the path.
When supplied, it is appended as one encoded segment. The high-level client's
mutation methods retain `withAuth: true` as their default; GET and `request`
default to false. The low-level `http` methods retain their default of false.

## Host and URLs

```dart
final host = Hosteday.client.host;             // https://max.hosteday.com
final api = Hosteday.client.apiBaseUrl;        // https://max.hosteday.com/api
```

Advanced API routing:

```dart
await Hosteday.initializeApp(options: {
  HostedayOptionKeys.projectDomain: 'max.hosteday.com',
  HostedayOptionKeys.apiBaseUrl: 'https://gateway.example.com/v2',
});
// /products -> https://gateway.example.com/v2/products
// host and public links still use https://max.hosteday.com
```

An override containing only an origin gets `/api`; an override with a path uses
that exact prefix. `base_url` remains an alias. Full REST URLs must use the
configured API origin, protecting project and user credentials from accidental
forwarding. Full media URLs may use other origins.

## Static Pages

```dart
final info = Hosteday.client.staticPages['info'];
final privacy = Hosteday.client.staticPages['/privacy/'];
// https://max.hosteday.com/info
// https://max.hosteday.com/privacy
```

Dart reserves `static`, so the property is named `staticPages`. It accepts one
non-empty slug and rejects traversal, query strings, fragments, and foreign URLs.
It builds a link without fetching the page or checking the platform's page quota.

## Storage & Media

```dart
final imageUrl = Hosteday.client.storageUrl('products/image.png');
// https://max.hosteday.com/storage/products/image.png
final cdn = Hosteday.client.storageUrl('https://cdn.example.com/image.png');
// unchanged
```

An existing `/storage/` prefix is not duplicated. Handle absent API image values
before calling `storageUrl`:

```dart
final imagePath = product['image'] as String?;
if (imagePath != null && imagePath.isNotEmpty) {
  Image.network(Hosteday.client.storageUrl(imagePath));
}
```

## Authentication

```dart
final credential = await Hosteday.auth.signInWithEmailAndPassword(
  email: 'customer@example.com', password: password,
);
final orders = await Hosteday.client.get('/orders', withAuth: true);
await Hosteday.auth.signOut();
```

```dart
await Hosteday.auth.createUserWithEmailAndPassword(
  email: email, password: password,
  additionalData: {'name': 'Customer'},
);
await Hosteday.auth.sendPasswordResetEmail(email: email);
await Hosteday.auth.reload();
await Hosteday.auth.sendEmailVerification();
```

Observe `Hosteday.auth.authStateChanges()` and read `Hosteday.auth.currentUser`.
For profile, avatar, password reset, session, and channel details see the
[API reference](doc/API_REFERENCE.md).

Default auth storage is in memory. To persist sessions:

```dart
await Hosteday.initializeApp(
  options: {HostedayOptionKeys.projectDomain: 'max.hosteday.com'},
  authStorage: HostedaySharedPreferencesAuthStorage(),
);
```

SharedPreferences is not encrypted storage. You can implement
`HostedayAuthStorage` for your platform's secure storage. For an external user
session, supply a `HostedayTokenProvider`; the SDK's active session takes priority.

## Project API Key

```dart
await Hosteday.initializeApp(options: {
  HostedayOptionKeys.projectDomain: 'max.hosteday.com',
  HostedayOptionKeys.projectApiKey: projectApiKey,
});
```

The existing platform header is preserved: `X-Api-Token`. Null, empty, and
whitespace-only keys send no header. `apiTokenHeader` supports an explicit
server-specific override. This key is separate from `Authorization: Bearer ...`,
which is added only for `withAuth: true` (or an explicitly supplied header).
Client configuration is visible in a compiled application; use client-scoped keys.

## Query Parameters & Search

```dart
final products = await Hosteday.client.get('/products',
  search: 'phone',
  queryParameters: {'category_id': 5, 'page': 2},
  filters: {'status': ['active', 'pending']},
);
```

Existing URL query values are preserved unless overridden. Null values are
omitted. Nested maps and lists use Laravel bracket syntax. Filters apply to index
GET requests only. Relation scoping remains available:

```dart
await Hosteday.client.get('/products', id: 15,
  relationField: 'category_id', relationValue: 5,
);
```

## Pagination / Responses

Responses retain the server's JSON structure, including pagination metadata.
A top-level JSON list is wrapped as `{'data': list}`. Empty responses return `{}`.
No sample records or fallback products are injected.

```dart
final response = await Hosteday.client.get('/products',
  queryParameters: {'page': 2},
);
final products = response['data'];
final nextPage = response['next_page_url'];
```

The server determines the exact pagination envelope. The example displays the
complete JSON and reads both `data: []` and `data: {data: []}` shapes.

## Error Handling

```dart
try {
  await Hosteday.client.get('/products', timeout: const Duration(seconds: 15));
} on HostedayException catch (error) {
  final status = error.statusCode;
  final developerMessage = error.message;
  final userMessage = error.displayMessage;
  final originalCause = error.error;
  final emailError = error.firstErrorFor('email');
}
```

Network failures and timeouts have distinct messages. Invalid JSON retains the
HTTP status and original body in `response['raw_body']`. HTTP errors retain the
server message, status, and validation errors, including 429, 430–433, and 5xx.
No undocumented meaning is assigned to Hosteday-specific status codes.

For compatibility, missing/invalid configuration throws `ArgumentError`, and
access before initialization or repeated initialization throws `StateError`, with
specific corrective messages. Runtime asset read/JSON errors use `HostedayException`.

## Realtime

REST works without Realtime configuration. To connect, supply both settings:

```dart
await Hosteday.initializeApp(options: {
  HostedayOptionKeys.projectDomain: 'max.hosteday.com',
  HostedayOptionKeys.realtimeAppKey: realtimeAppKey,
  HostedayOptionKeys.realtimeHost: realtimeHost,
});
if (Hosteday.config.hasRealtime) {
  await Hosteday.connectRealtime();
}
```

Listen using `listenPublic`, `listenPrivate`, or `listenPresence` as shown in the
[Realtime example](example/lib/features/realtime/presentation/pages/realtime_page.dart).
Private and presence subscriptions require user authentication. Publishing follows
the same distinction:

```dart
await Hosteday.client.publishPublicEvent(
  channel: 'products', event: 'updated', payload: {'id': 15},
);
await Hosteday.client.publishPrivateEvent(
  channel: 'orders', event: 'updated', payload: {'id': 42},
);
await Hosteday.disconnectRealtime();
```

## Complete Example

This minimal app displays the real server response:

```dart
import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hosteday.initializeApp(options: {
    HostedayOptionKeys.projectDomain: 'max.hosteday.com',
  });
  final request = Hosteday.client.get('/products');
  runApp(MaterialApp(home: Scaffold(body: SafeArea(
    child: FutureBuilder<Map<String, dynamic>>(
      future: request,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text(snapshot.error.toString());
        if (!snapshot.hasData) return const CircularProgressIndicator();
        return SingleChildScrollView(child: Text(snapshot.data.toString()));
      },
    ),
  ))));
}
```

The [interactive example](example/README.md) includes all HTTP verbs, search,
query parameters, real response rows and images, URL helpers, account flows,
and optional Realtime. On Web, `/categories` is sent to `/api/categories`;
CORS must be configured by the server.

## Migration and verification

Old `HosteDay...` spellings remain deprecated compatibility APIs. New code uses
`Hosteday...`. See [migration notes](doc/MIGRATION.md) for URL behavior changes,
[architecture](doc/ARCHITECTURE.md), and [verification status](doc/VERIFICATION.md).

```bash
flutter pub get
dart format lib test example/lib example/test
flutter analyze
flutter test
cd example
flutter pub get
flutter analyze
flutter test
```

This is a Flutter package: run its `flutter_test` suite with `flutter test`, not
standalone `dart test`.
