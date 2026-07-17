# HosteDay Flutter Example

A complete Flutter example app demonstrating how to use the `hosteday_flutter` package with HosteDay
services.

This example is designed to help developers initialize HosteDay, authenticate users, persist
sessions, manage user profiles, upload avatars, connect to realtime services, and perform complete
CRUD operations on a custom `posts` API table.

---

## What this example includes

This example demonstrates:

* HosteDay SDK initialization.
* Optional project API protection through `X-Api-Token`.
* Persistent authentication session storage using `shared_preferences`.
* Email/password sign in.
* Email/password registration.
* Navigation to the home page after successful sign in or registration.
* Password reset email requests.
* Authentication state handling using streams.
* A shared AppBar that reacts automatically to authentication changes.
* Current user display.
* User profile reload and update.
* User avatar selection and upload.
* Full HTTPS avatar URL handling.
* Email verification requests.
* Sign out.
* Realtime connection setup.
* Custom API usage through the public `HosteDay.client` interface.
* Listing, showing, creating, updating, and deleting posts.
* Search and relation query parameters.
* Public and authenticated API requests.
* Common Laravel API response parsing.
* Laravel validation and database error handling.

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
│   │   ├── errors/
│   │   │   └── error_presenter.dart
│   │   ├── theme/
│   │   │   └── example_theme.dart
│   │   └── utils/
│   │       └── api_response_reader.dart
│   ├── features/
│   │   ├── auth/
│   │   │   └── presentation/
│   │   │       ├── auth_gate.dart
│   │   │       └── pages/
│   │   │           ├── forgot_password_page.dart
│   │   │           ├── register_page.dart
│   │   │           └── sign_in_page.dart
│   │   ├── posts/
│   │   │   ├── data/
│   │   │   │   └── post_repository.dart
│   │   │   ├── models/
│   │   │   │   └── post_model.dart
│   │   │   └── presentation/
│   │   │       ├── pages/
│   │   │       │   └── home_page.dart
│   │   │       └── widgets/
│   │   │           ├── post_card.dart
│   │   │           └── post/
│   │   │               ├── create_page.dart
│   │   │               ├── delete.dart
│   │   │               ├── index.dart
│   │   │               ├── show.dart
│   │   │               └── update_page.dart
│   │   ├── profile/
│   │   │   └── presentation/
│   │   │       └── pages/
│   │   │           └── profile_page.dart
│   │   └── realtime/
│   └── shared/
│       └── widgets/
│           ├── app_bar_my.dart
│           ├── empty_box.dart
│           ├── example_header.dart
│           ├── example_scaffold.dart
│           ├── feedback_boxes.dart
│           └── form_fields.dart
├── pubspec.yaml
└── README.md
```

---

## Required HosteDay values

Before running the example, you need the HosteDay values used by your project:

```txt
HOSTEDAY_PROJECT_DOMAIN
HOSTEDAY_PROJECT_API_KEY
HOSTEDAY_REALTIME_APP_KEY
HOSTEDAY_REALTIME_HOST
```

Example:

```txt
HOSTEDAY_PROJECT_DOMAIN=project.hosteday.com
HOSTEDAY_PROJECT_API_KEY=your_real_project_api_key
HOSTEDAY_REALTIME_APP_KEY=your_realtime_app_key
HOSTEDAY_REALTIME_HOST=project.hosteday.com
```

`HOSTEDAY_PROJECT_DOMAIN` is required. `HOSTEDAY_PROJECT_API_KEY` is only required when project API
protection is enabled. Realtime values are only required when the realtime example is used.

Never use the literal placeholder `YOUR_PROJECT_ACCESS_TOKEN` as a project API key. If project API
protection is disabled, omit the key or leave it empty instead of sending a placeholder value.

The project API key and the authenticated user access token are different credentials:

* The project API key is sent through `X-Api-Token` when project API protection is enabled.
* The user access token is sent through `Authorization: Bearer ...` when `withAuth` is `true`.
* The user access token is created after sign in and is managed automatically by HosteDay Auth.

Do not print either token in application logs or commit them to source control.

---

## Example dependencies

The example uses `shared_preferences` for session persistence and `image_picker` for selecting
profile images.

Use the following structure in `example/pubspec.yaml`:

```yaml
name: hosteday_flutter_example
description: HosteDay Flutter example app.
publish_to: "none"

environment:
  sdk: ^3.11.5

dependencies:
  flutter:
    sdk: flutter

  hosteday_flutter:
    path: ..

  shared_preferences: ^2.5.3
  image_picker: ^1.2.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
```

`path: ..` and `path: ../` both point to the local package root. A path dependency uses the package
source directly and does not download a published copy.

After changing the package API, stop the example completely and run:

```bash
cd example
flutter clean
flutter pub get
flutter run
```

If the IDE still displays an old API, restart the Dart Analysis Server.

---

## Running the example

From the package root:

```bash
cd example

flutter pub get

flutter run \
  --dart-define=HOSTEDAY_PROJECT_DOMAIN=project.hosteday.com \
  --dart-define=HOSTEDAY_PROJECT_API_KEY=your_real_project_api_key \
  --dart-define=HOSTEDAY_REALTIME_APP_KEY=your_realtime_app_key \
  --dart-define=HOSTEDAY_REALTIME_HOST=project.hosteday.com
```

When project API protection is disabled, omit the project key:

```bash
flutter run \
  --dart-define=HOSTEDAY_PROJECT_DOMAIN=project.hosteday.com
```

If Android, iOS, Web, Linux, macOS, or Windows folders do not exist yet, generate them once from the
example directory:

```bash
flutter create .
```

Then run the app again:

```bash
flutter run
```

---

## SDK initialization

HosteDay is initialized before running the Flutter app:

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
HosteDayOptionKeys.projectDomain:
ExampleEnvironment.projectDomain,
if (ExampleEnvironment.projectApiKey.isNotEmpty)
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

Authentication paths and user API paths are managed internally by HosteDay and are not configured
through initialization options.

---

## Environment configuration

The example reads configuration through `--dart-define`:

```dart
abstract final class ExampleEnvironment {
  static const String projectDomain = String.fromEnvironment(
    'HOSTEDAY_PROJECT_DOMAIN',
    defaultValue: 'project.hosteday.com',
  );

  static const String projectApiKey = String.fromEnvironment(
    'HOSTEDAY_PROJECT_API_KEY',
    defaultValue: '',
  );

  static const String realtimeAppKey = String.fromEnvironment(
    'HOSTEDAY_REALTIME_APP_KEY',
    defaultValue: '',
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

The first argument passed to `String.fromEnvironment` must be the environment variable name, not the
project domain.

Correct:

```dart

static const String projectDomain = String.fromEnvironment(
  'HOSTEDAY_PROJECT_DOMAIN',
  defaultValue: 'project.hosteday.com',
);
```

Incorrect:

```dart

static const String projectDomain = String.fromEnvironment(
  'https://project.hosteday.com',
  defaultValue: 'https://project.hosteday.com',
);
```

---

## Public SDK interface

Application code should use the high-level client:

```dart
HosteDay.client
```

`HosteDayHttpClient` is the internal transport responsible for building URLs, applying headers,
encoding JSON, sending requests, decoding responses, handling timeouts, and converting API errors.
It should remain internal and does not need to be exported from the package entry point.

The package entry point should not expose:

```dart
export 'src/http/hosteday_http_client.dart';
```

The high-level `HosteDayClient` delegates requests internally while presenting the public API:

```dart
HosteDay.client.get
(...);HosteDay.client.post(...);
HosteDay.client.put(...);
HosteDay.client.patch(...);
HosteDay.client.delete
(
...
);
```

All generic request methods should default to:

```dart

bool withAuth = false
```

Set `withAuth: true` only for routes protected by user authentication. This keeps public routes,
public realtime publishing, and authenticated routes clearly separated.

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

After successful sign in, the example removes the previous navigation stack and opens `HomePage`:

```dart
if (!mounted) {
return;
}

Navigator.of(context).pushAndRemoveUntil(
MaterialPageRoute<void>(
builder: (_) => const HomePage(),
),
(route) =>
false
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

After successful registration, the example also opens `HomePage` and removes the previous routes. If
a project requires email verification before access, navigate to an email verification page instead.

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

The Flutter app only requests the password reset email. The password reset is completed through the
web link sent to the user.

---

## Authentication state

The example uses `authStateChanges()` to decide whether to show the sign-in page or the
authenticated application:

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

Do not use a forced null assertion such as:

```dart
HosteDay.auth.currentUser!.
hasEmail
```

The user may be `null` while the session is being restored. Use a null-safe condition:

```dart

final isAuthenticated = user?.hasEmail == true;
```

If any non-null user is considered authenticated regardless of email, use:

```dart

final isAuthenticated = user != null;
```

---

## Shared authentication AppBar

`AppBarMy` contains Home, Sign in, Create account, Profile, and Sign out actions internally. Pages
only provide a title:

```dart
Scaffold
(
appBar: const AppBarMy(
title: 'Posts',
),
body: const Index(),
);
```

The account menu listens to authentication changes inside the shared AppBar:

```dart
StreamBuilder<HosteDayUser?>
(
stream: HosteDay.auth.authStateChanges(),
initialData: HosteDay.auth.currentUser,
builder: (context, snapshot) {
final user = snapshot.data;
final isAuthenticated = user?.hasEmail == true;

return PopupMenuButton<_AccountAction>(
tooltip: 'Account menu',
icon: Icon(
isAuthenticated
? Icons.account_circle
    : Icons.account_circle_outlined,
),
onSelected: (action) async {
await _handleAccountAction(context, action);
},
itemBuilder: (_) => _buildMenuItems(user),
);
},
);
```

Unauthenticated users see:

```txt
Sign in
Create account
```

Authenticated users see:

```txt
Profile
Sign out
```

---

## Persistent session storage

The example uses:

```dart
HosteDaySharedPreferencesAuthStorage
()
```

This stores the authenticated session locally using `shared_preferences`, allowing the user to stay
signed in after closing and reopening the app.

If the project domain changes during development, sign out and sign in again so an old token from
another project is not restored and sent to the new domain.

---

## User profile

The example demonstrates reading the current user, listening for user changes, reloading the user,
updating the user's name, uploading an avatar, and requesting email verification.

Currently, the HosteDay API supports updating the user's name through `updateProfile`. Additional
profile fields may be supported in future versions.

```dart

final currentUser = HosteDay.auth.currentUser;

final stream = HosteDay.auth.userChanges();

final reloadedUser = await
HosteDay.auth.reload
();

final updatedUser = await
HosteDay.auth.updateProfile
(
name: name,
);

await HosteDay.auth.sendEmailVerification
(
);
```

Email verification is completed through the web link sent by email. The Flutter app only requests
sending the verification email.

---

## User avatar upload

The example uses `image_picker` to select an image from the gallery or camera. The selected file is
read as bytes, while `hosteday_flutter` converts the bytes to Base64 and sends them to the HosteDay
API.

### Supported image extensions

The avatar endpoint accepts:

```txt
jpg
jpeg
png
webp
```

### Select and upload an avatar

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

  final extension = image.name
      .split('.')
      .last
      .trim()
      .toLowerCase();

  return HosteDay.auth.updateAvatar(
    bytes: bytes,
    extension: extension,
  );
}
```

The SDK sends a request equivalent to:

```json
{
  "bytes": "BASE64_ENCODED_IMAGE_BYTES",
  "extension": "png"
}
```

Do not manually add a prefix such as:

```txt
data:image/png;base64,
```

The SDK sends the Base64 value expected by the HosteDay API.

---

## Avatar URL returned by the API

The backend may store only a relative avatar path in the database:

```txt
users/USER_ID/IMAGE.png
```

The API should return a complete HTTPS URL when serializing the user:

```json
{
  "avatar": "https://project.hosteday.com/users/USER_ID/IMAGE.png"
}
```

The Flutter SDK reads common avatar keys including:

```txt
avatar
avatar_url
avatarUrl
photo_url
photoUrl
image
image_url
imageUrl
```

The complete avatar URL is available through:

```dart

final user = HosteDay.auth.currentUser;

final photoUrl = user?.photoUrl;
final avatarUrl = user?.avatarUrl;
```

`avatarUrl` is an alias for `photoUrl`.

### Display the avatar

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

Because avatar updates publish a new user through `userChanges()`, a `StreamBuilder<HosteDayUser?>`
can refresh the displayed image automatically:

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

Gallery selection normally does not require manually adding legacy storage permissions when using
current Android and `image_picker` versions.

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

Gallery selection is supported through the browser file picker. Camera behavior depends on browser
capabilities and permissions. The example should prefer gallery selection where camera capture is
unavailable.

---

## Sign out

```dart
await
HosteDay.auth.signOut
();
```

After signing out, the stored session is cleared and the example replaces the current navigation
stack with `AuthGate`.

---

## Custom API example: posts

The example includes a custom table named `posts` and demonstrates complete CRUD operations.

Expected endpoints:

```http
GET    /api/posts
GET    /api/posts/{id}
POST   /api/posts
PUT    /api/posts/{id}
PATCH  /api/posts/{id}
DELETE /api/posts/{id}
```

The SDK base URL already includes `/api`, so application code uses `/posts` rather than
`/api/posts`.

### Recommended posts table columns

```txt
id          BIGINT or integer primary key
user_id     VARCHAR(255)
title       VARCHAR(255)
body        TEXT or LONGTEXT
created_at  TIMESTAMP
updated_at  TIMESTAMP
```

Use `TEXT` or `LONGTEXT` for `body` when posts may contain articles or text longer than 255
characters. Do not use `VARCHAR(255)` for long content.

### Create validation

```json
{
  "body": "required|string|min:10|max:10000",
  "title": "required|string|max:255",
  "user_id": "sometimes|string|max:255"
}
```

### Update validation

```json
{
  "id": [
    "required",
    "integer"
  ],
  "body": "sometimes|string|min:10|max:10000",
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

### Delete validation

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

---

## Posts request parameters

The SDK exposes Dart parameters so application developers do not need to write raw query parameter
keys such as `relation_field` or `relation_value`.

Supported resource parameters include:

* `id`: appended to the path for show, update, patch, and delete requests.
* `search`: added as the `search` query parameter.
* `relationField`: added as the `relation_field` query parameter.
* `relationValue`: added as the `relation_value` query parameter.

`relationField` and `relationValue` must be provided together.

Example index URL:

```txt
/api/posts?search=Flutter&relation_field=user_id&relation_value=USER_ID
```

Example show URL:

```txt
/api/posts/12?relation_field=user_id&relation_value=USER_ID
```

Example update URL:

```txt
/api/posts/12?relation_field=user_id&relation_value=USER_ID
```

---

## List posts: index

The `Index` widget is now responsible only for loading, displaying, and manually refreshing posts.
Post creation and realtime subscriptions are not embedded in the index page.

```dart

final response = await
HosteDay.client.get
('/posts
'
,search: search,
relationField: 'user_id',
relationValue:
userId
,
withAuth
:
false
,
);
```

For a protected route, use:

```dart
withAuth: true
```

The list is displayed through `PostCard`, and the page supports pull-to-refresh through
`RefreshIndicator`.

---

## Show one post

```dart

final response = await
HosteDay.client.get
('/posts
'
,id: 12,
relationField: 'user_id',
relationValue:
userId
,
withAuth
:
false
,
);
```

The generated URL is:

```txt
/api/posts/12?relation_field=user_id&relation_value=USER_ID
```

Use `ApiResponseReader.readObject(response)` when reading a show response.

---

## Create a post

`CreatePage` owns its form controllers, loading state, validation errors, and repository request.
After success, it returns `true` to the previous page.

```dart

final title = titleController.text.trim();
final postBody = bodyController.text.trim();
final userId = userIdController.text.trim();

final requestBody = <String, dynamic>{
  'title': title,
  'body': postBody,
  if (userId.isNotEmpty) 'user_id': userId,
};

await
HosteDay.client.post
('/posts
'
,body:
requestBody
,
withAuth
:
false
,
);
```

`user_id` is included inside the JSON body only when it has a non-empty value because its validation
rule uses `sometimes`.

For a protected create route, change `withAuth` to `true`.

---

## Update a post

`UpdatePage` receives the post ID, relation field, relation value, and initial post values. It owns
its controllers and sends only changed, non-empty fields.

```dart

final requestBody = <String, dynamic>{
  if (title.isNotEmpty && title != initialTitle)
    'title': title,
  if (postBody.isNotEmpty && postBody != initialBody)
    'body': postBody,
  if (userId.isNotEmpty && userId != initialUserId)
    'user_id': userId,
};

await
HosteDay.client.put
('/posts
'
,id: postId,
relationField: 'user_id',
relationValue: relationValue,
body: requestBody,
withAuth: false,
);
```

For protected update routes, use `withAuth: true`.

After a successful update:

```dart
Navigator.of
(
context
)
.
pop
(
true
);
```

`PostCard` opens `UpdatePage` from its Edit button and reloads the list when the page returns
`true`.

---

## Delete a post

Delete is implemented as a confirmation action instead of an independent top-level navigation page.

```dart
await
HosteDay.client.delete
('/posts
'
,id: postId,
relationField: 'user_id',
relationValue:
relationValue
,
withAuth
:
false
,
);
```

For protected delete routes, use `withAuth: true`.

The generated URL is:

```txt
DELETE /api/posts/12?relation_field=user_id&relation_value=USER_ID
```

No JSON body is required for the delete validation shown above.

---

## Posts navigation flow

CRUD actions are connected through normal Navigator routes instead of placing all five operations
inside a `PageView`:

```txt
Index → Create
Index → Show → Update
             → Delete confirmation
```

* `HomePage` displays `Index`.
* A floating action button opens `CreatePage`.
* Selecting a post opens `Show`.
* The Edit action opens `UpdatePage`.
* The Delete action displays a confirmation dialog.
* Create, update, and delete return a result so the previous page can reload data.

This flow avoids treating forms and destructive actions as permanent top-level tabs.

---

## Reading API responses

`ApiResponseReader` accepts common Laravel response shapes.

List responses may be returned as:

```json
{
  "data": []
}
```

Paginated responses may be returned as:

```json
{
  "data": {
    "data": []
  }
}
```

Custom list responses may be returned as:

```json
{
  "posts": []
}
```

Read and convert a list:

```dart

final posts = ApiResponseReader.readList(response)
    .map(PostModel.fromJson)
    .toList()
  ..sort(
        (a, b) => b.createdAtText.compareTo(a.createdAtText),
  );
```

Use a plural variable name such as `posts` because the value is a `List<PostModel>`.

Read a single object:

```dart

final json = ApiResponseReader.readObject(response);

if (
json == null) {
throw const FormatException(
'Post data was not found in the response.',
);
}

final post = PostModel.fromJson(json);
```

---

## Post model

`PostModel` supports `user_id` and common alternative keys:

```dart

final userId = ApiResponseReader.firstText(
  json,
  const <String>[
    'user_id',
    'userId',
    'author_id',
    'owner_id',
  ],
);
```

The value is assigned when constructing the model:

```dart
return PostModel(
id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
userId: userId ?? '',
title: title ?? 'Untitled post',
body: body,
createdAtText: createdAtText,
data: Map<String, dynamic>.from(
json
)
,
);
```

Before opening update or delete actions, verify that `userId` is not empty:

```dart
if (post.userId.trim().isEmpty) {
return;
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

The realtime app key is provided by HosteDay and does not require a Pusher account. HosteDay uses a
Pusher-compatible realtime protocol internally.

Realtime is demonstrated as a separate feature. The current `Index` page does not subscribe to
realtime events; it only loads and refreshes posts.

### Expected realtime event

```txt
channel: posts
event: PostCreated
```

Expected payload:

```json
{
  "post": {
    "id": 2,
    "user_id": "USER_ID",
    "title": "New post",
    "body": "Created from another client."
  }
}
```

---

## Troubleshooting

### Local package changes do not appear in the example

The example uses a local path dependency, so source changes under the package `lib` directory are
used directly. Stop the running application and execute:

```bash
cd example
flutter clean
flutter pub get
flutter run
```

Ensure new public files are exported from `lib/hosteday_flutter.dart`. Internal files such as
`HosteDayHttpClient` do not need to be exported.

### `HosteDay request error`

This usually means one of the following:

* The project domain is incorrect.
* The backend returned a non-JSON response.
* The API endpoint is unavailable.
* The app uses old environment variable names.
* A project API key is missing while project API protection is enabled.
* A placeholder project API key is being sent.

Use:

```bash
--dart-define=HOSTEDAY_PROJECT_DOMAIN=project.hosteday.com
--dart-define=HOSTEDAY_PROJECT_API_KEY=your_real_project_api_key
```

Do not use the old environment variable name:

```bash
HOSTEDAY_PROJECT_ACCESS_TOKEN
```

### `Missing authentication token`

This error is generated by the SDK before the request is sent. It means `withAuth` is `true`, but
the token provider did not return a stored user access token.

Make sure the user is signed in before calling a protected route:

```dart
withAuth: true
```

### `Unauthenticated.` with status 401

This response comes from the backend. It means the server did not accept the user access token for
the requested route.

Check the following:

* The route really uses user authentication such as `auth:sanctum`.
* The request uses `withAuth: true` only when the route is protected.
* The token was created for the same project domain receiving the request.
* An old session from another project is not being restored.
* The final request URL uses HTTPS and does not redirect to another host.
* The same token works against the project's user endpoint.

Project API protection and user authentication are separate. Disabling `X-Api-Token` protection does
not automatically remove an `auth:sanctum` middleware from a route.

For public routes, explicitly use:

```dart
withAuth: false
```

If a request still returns 401 without an `Authorization` header, the route or a global middleware
is still requiring authentication.

Do not use `HosteDay.auth.currentUser!.hasEmail` as proof that the server will accept the stored
token. A local user object may exist while its token is stale, revoked, or issued for another
domain.

### `Data too long for column 'body'`

This database error means the post body is larger than the database column capacity. It commonly
occurs when `body` is defined as `VARCHAR(255)` but the application sends an article or another long
text value.

Change the column to `TEXT`:

```php
Schema::table('posts', function (Blueprint $table): void {
    $table->text('body')->change();
});
```

Use `LONGTEXT` for very large content:

```php
Schema::table('posts', function (Blueprint $table): void {
    $table->longText('body')->change();
});
```

Keep request validation and Flutter form limits aligned with the database column.

### Avatar upload fails

Check the following:

* The user is authenticated.
* The selected image is not empty.
* The extension is one of `jpg`, `jpeg`, `png`, or `webp`.
* The backend accepts the `bytes` and `extension` fields.
* The backend Base64 limit and request size limit are large enough.
* The backend storage directory is writable.
* The API returns the updated user after upload or supports reloading the current user.

### Avatar URL uses HTTP

The backend should return the avatar URL with HTTPS. For Laravel applications behind a reverse
proxy, ensure the application URL is configured correctly:

```env
APP_URL=https://project.hosteday.com
```

The backend may store a relative path in the database and return the complete HTTPS URL from its
user resource.

Example database value:

```txt
users/USER_ID/IMAGE.png
```

Example API value:

```txt
https://project.hosteday.com/users/USER_ID/IMAGE.png
```

### Avatar does not refresh after upload

The `updateAvatar()` implementation should update or reload the authenticated user after a
successful request. Use `userChanges()` to rebuild widgets when the current user changes:

```dart
StreamBuilder<HosteDayUser?>
(
stream: HosteDay.auth.userChanges(),
initialData: HosteDay.auth.currentUser,
builder: (context, snapshot) {
final user = snapshot.data;

return Text(user?.avatarUrl ?? 'No avatar');
},
);
```

### Realtime does not connect

Check these values:

```bash
--dart-define=HOSTEDAY_REALTIME_APP_KEY=your_realtime_app_key
--dart-define=HOSTEDAY_REALTIME_HOST=project.hosteday.com
```

Make sure the realtime app key is not the same as the project API key.

### Do not log authentication tokens

Never print the complete headers map:

```dart
print(requestHeaders);
```

Use a safe diagnostic instead:

```dart
debugPrint
('Authorization attached: 
'
'${requestHeaders.containsKey('Authorization')}'
,
);
```

If a token is accidentally exposed, revoke it and sign in again to obtain a new token.

---

## Notes

This example is intentionally educational. It separates application concerns into clear sections:

* `core` for configuration, initialization, theme, errors, and utilities.
* `features` for authentication, posts, profile, and realtime.
* `shared` for reusable widgets such as fields, feedback boxes, scaffolds, and the shared AppBar.
* `HosteDayClient` as the public HTTP interface.
* `HosteDayHttpClient` as an internal transport implementation.

For a quick test, see `EXAMPLE.md` and the Quick Experience section.
