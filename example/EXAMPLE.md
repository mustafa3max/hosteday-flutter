# HosteDay Flutter Complete Example

This example is a small but complete Flutter app that demonstrates how to use
`hosteday_flutter` in a clean educational structure.

## Quick Experience Example

If you only want to test HosteDay quickly without exploring the full structured example, start here:

[Open the Quick Experience example](#quick-experience-example)

The Quick Experience is a single-file Flutter example designed to test the platform fast. It
includes SDK initialization, persistent session storage, sign in, registration, password reset
email, user data display, email verification request, user reload, and sign out.

---

It covers:

- Email/password sign in.
- Email/password registration.
- Forgot-password email flow.
- Auth state handling through an `AuthGate`.
- Current user profile display.
- User profile update.
- Email verification request.
- Custom API table example using `/api/posts`.
- Creating posts with authenticated requests.
- Listening to realtime `PostCreated` events.

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

## File responsibilities

### `lib/main.dart`

Small entry point. It initializes Flutter bindings, initializes HosteDay, then
runs the example app.

### `lib/app.dart`

Defines `HosteDayExampleApp`, the root `MaterialApp`, the theme, and the first
screen: `AuthGate`.

### `lib/core/bootstrap/hosteday_initializer.dart`

Keeps SDK initialization in one place. This makes it easy to replace example
configuration with production values later.

### `lib/core/config/example_environment.dart`

Contains compile-time configuration read from `--dart-define`:

- `HOSTEDAY_PROJECT_DOMAIN`
- `HOSTEDAY_PROJECT_ACCESS_TOKEN`
- `HOSTEDAY_REALTIME_APP_KEY`
- `HOSTEDAY_REALTIME_HOST`
- `HOSTEDAY_REALTIME_SCHEME`
- `HOSTEDAY_REALTIME_PORT`

The file also includes backward-compatible option keys such as `pusher_key` so
older SDK versions can still read the realtime app key.

### `lib/features/auth/presentation/auth_gate.dart`

Listens to `HosteDay.auth.authStateChanges()` and decides whether the app should
show `SignInPage` or `HomeShell`.

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
additionalData: {'name': name},
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
);
```

The actual password reset can be completed through the web flow opened from the
email link.

### `lib/features/home/presentation/home_shell.dart`

Authenticated app shell. It contains the bottom navigation tabs:

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

Demonstrates:

```dart
HosteDay.auth.currentUser;HosteDay.auth.userChanges
();await
HosteDay.auth.reload
();await
HosteDay.auth.updateProfile
(
{'name
'
: name});
await HosteDay.auth.sendEmailVerification();
```

### `lib/features/posts/data/post_repository.dart`

Contains HTTP requests for a custom backend table named `posts`:

```dart
await
HosteDay.client.get
('/api/posts
'
, withAuth: true);
await HosteDay.client.post('/api/posts', withAuth: true, body: {...});
```

The UI does not call HTTP directly. This keeps the example easier to understand
and closer to real app structure.

### `lib/features/posts/data/post_realtime_service.dart`

Connects to realtime and listens for post events:

```dart
await
HosteDay.connectRealtime
();

HosteDay.realtime.listenPublic
(
channel: 'posts',
event: 'PostCreated',
onEvent: (event) {},
);
```

### `lib/features/posts/presentation/pages/posts_page.dart`

Combines the repository and realtime service:

- Loads posts on page start.
- Refreshes posts with pull-to-refresh.
- Creates a new post.
- Updates the list when a realtime event arrives.

### `lib/shared/widgets/*`

Reusable UI widgets used across the example:

- `ExampleScaffold`
- `ExampleHeader`
- `EmailField`
- `PasswordField`
- `ErrorBox`
- `SuccessBox`
- `InfoTile`
- `EmptyBox`

---

## Backend requirements

The example expects these endpoints to exist in the HosteDay project backend.

### Authentication

These depend on your SDK/backend configuration:

- Sign in
- Register
- Forgot password
- Current user
- Update user profile
- Send email verification
- Sign out

### Posts table

The custom table example expects:

```http
GET /api/posts
POST /api/posts
```

A simple successful list response can be:

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

A simple successful create response can be:

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

Expected payload examples:

```json
{
  "post": {
    "id": 2,
    "title": "New post",
    "body": "Created from another client."
  }
}
```

or:

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
  --dart-define=HOSTEDAY_PROJECT_DOMAIN=https://your-project.hosteday.com \
  --dart-define=HOSTEDAY_PROJECT_ACCESS_TOKEN=your_public_project_token \
  --dart-define=HOSTEDAY_REALTIME_APP_KEY=your_realtime_app_key \
  --dart-define=HOSTEDAY_REALTIME_HOST=your-project.hosteday.com
```

For Android/iOS/Web folders, run this once inside `example/` if they do not
exist yet:

```bash
flutter create .
```

---

## Why this structure is educational

This example separates concerns clearly:

- `core` contains SDK initialization, config, theme, and utilities.
- `features` contains real app sections.
- `data` contains API/realtime access.
- `models` contains plain Dart models.
- `presentation` contains screens and widgets.
- `shared` contains reusable UI pieces.

This gives new users a full example that is still easy to read and modify.
