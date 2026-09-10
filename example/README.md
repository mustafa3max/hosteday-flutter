# Hosteday interactive example

This app connects to the configured project. It does not create tables, insert
sample records, or substitute offline data when requests fail.

## Run

```bash
flutter pub get
flutter run --dart-define=HOSTEDAY_PROJECT_DOMAIN=max.hosteday.com
```

If your project requires a client API key, add
`--dart-define=HOSTEDAY_PROJECT_API_KEY=your_client_key`.
To enable Realtime, also supply `HOSTEDAY_REALTIME_APP_KEY` and
`HOSTEDAY_REALTIME_HOST`. These are optional for REST.

## API explorer

The startup screen displays the project's `host` and `apiBaseUrl`.
Choose any table endpoint that exists in your project:

1. GET `/products`, search `phone`, query `{"page":2,"category_id":5}`.
2. POST `/products` with the fields required by your actual table schema.
3. PUT or PATCH `/products/15` with the intended changes.
4. DELETE `/products/15` to delete that record.

Use the authentication switch for protected endpoints. The screen displays real
response JSON, pagination metadata, returned rows, and images resolved through
`storageUrl`. API errors appear with their status and message.
The slug and media inputs exercise `staticPages` and `storageUrl` directly.

## Account and posts

The Account button opens the existing auth gate: sign in, register, or request
a password reset. Signed-in users can access the posts CRUD UI, profile/avatar
management, and Realtime tabs. These post screens expect a `posts` table with
`id`, `user_id`, `title`, `body`, `status`, and `created_at` fields. The explorer
works with other table schemas without changing those post screens.

## Realtime

The startup Realtime button is enabled only when a host and key are configured.
The existing Realtime screen demonstrates subscription and publishing. Private
and presence channels require an authenticated user. REST works with no socket.

## Files

| File / directory | Purpose |
| --- | --- |
| `lib/core/config/example_environment.dart` | Public compile-time configuration |
| `lib/core/bootstrap/hosteday_initializer.dart` | SDK initialization and session persistence |
| `lib/features/explorer/` | All HTTP verbs, URLs, query/search, real responses |
| `lib/features/auth/` | Account screens and auth gate |
| `lib/features/posts/` | Structured repository and posts CRUD screens |
| `lib/features/profile/` | User profile and avatar |
| `lib/features/realtime/` | Channel/event demonstration |

Generated applications may instead declare `assets/config/hosteday.json` and
call `Hosteday.initializeFromAsset()` as documented in the package README.

## Verify

```bash
flutter analyze
flutter test
```

The widget test verifies startup URL display without making backend requests.
The complete package test suite is in `../test`.
