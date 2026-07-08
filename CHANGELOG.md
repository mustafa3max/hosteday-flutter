## 2.0.0 - 2026-07-08

### Breaking Changes

- Renamed `HosteDayOptionKeys.apiToken` to `HosteDayOptionKeys.projectApiKey`.
- Renamed `HosteDayOptionKeys.apiTokenHeader` to `HosteDayOptionKeys.projectApiKeyHeader`.
- Renamed `HosteDayOptionKeys.pusherKey` to `HosteDayOptionKeys.realtimeAppKey`.
- Removed old configurable authentication and user path option keys.
- Authentication and user endpoints are now fixed by HosteDay and cannot be overridden from
  `initializeApp`.
- Removed the old `Hosteday` compatibility entry point. Use `HosteDay` instead.
- Updated initialization examples to use project-level naming instead of generic token naming.

### Added

- Added `HosteDaySharedPreferencesAuthStorage` for persistent session storage using
  `shared_preferences`.
- Added `projectApiKey` and `projectApiKeyHeader` option names to clarify project-level
  authentication.
- Added `realtimeAppKey` option name to avoid implying that developers need a Pusher account.
- Added realtime configuration support for `realtimeScheme` and `realtimePort`.
- Added improved Laravel-style validation error parsing through `HosteDayException`.
- Added better validation error helpers such as `displayMessage`, `firstErrorFor`, and
  `hasValidationErrors`.
- Added improved `HosteDayUser` parsing for common Laravel fields such as `email_verified_at`.
- Added improved `HosteDayRealtimeEvent` helpers, including `data`, `operator []`, `containsKey`,
  and `toJson`.
- Added a complete structured Flutter example app.
- Added a quick single-file experience example.
- Added more complete README documentation with examples for auth, users, HTTP requests, posts,
  realtime, and errors.

### Changed

- Updated examples to use `HosteDaySharedPreferencesAuthStorage`.
- Updated examples to use `projectApiKey` instead of `apiToken`.
- Updated examples to use `realtimeAppKey` instead of `pusherKey`.
- Updated README and example documentation to explain the relationship between the SDK and the
  HosteDay platform.
- Improved HosteDay example theme to match the HosteDay visual identity.
- Improved HTTP request handling with query parameters and request timeout support.
- Improved realtime connection setup to use `realtimeScheme` and `realtimePort` from
  `HosteDayConfig`.

### Fixed

- Fixed realtime connection configuration previously using hard-coded `wss` and `443`.
- Fixed misleading auth/user path configuration exposure.
- Fixed invalid or unclear README code formatting.
- Fixed example session loss by using persistent storage.
- Fixed confusing naming that made project API keys look like user authentication tokens.
- Fixed confusing realtime naming that implied developers needed a Pusher account.