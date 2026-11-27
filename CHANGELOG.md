## 2.5.0

### Added
- **Unified Asset Initialization**: Streamlined single-source initialization from `assets/hosteday_config.json` via `await Hosteday.initializeApp()`.
- **Per-Auction Presence Rooms & Channel Switching**: Added `subscribePrivate`, prefix-aware `unsubscribe` across `presence-` / `private-` / `private-encrypted-` channels, and immediate re-authorization when switching between live presence channels.
- **Upgraded Live Auction Reference App**: Refactored `example/` Live Bidding screen into a consumer-facing auction hall with an auction selector dropdown, independent per-auction presence rooms (`auction.{id}`), official `publishPresenceEvent` broadcasting, and resilient nested payload decoding.

### Improved
- Sanitized example configuration files to placeholder demo values and removed temporary debug logging.
- Updated documentation with the official HosteDay Flutter SDK portal link (`https://hosteday.com/sdks/hosteday-flutter`).

## 2.4.0

### Added
- **Zero-Config SDK Initialization**: Direct initialization using typed `HostedayConfig` via `Hosteday.initializeApp(config: HostedayConfig(...))` with intelligent defaults for all standard endpoints.
- **Built-in Connectivity Monitoring**: Added `Hosteday.connectivity` and synchronous `Hosteday.isOnline` powered by `internet_connection_checker_plus` and real-time browser online/offline events via `package:web`.
- **HostedayConnectivityBanner**: Ready-to-use reactive UI banner widget that automatically slides down during network disconnects and auto-hides upon reconnection.
- **Typed Response Models**: Added `HostedayJobResponse` and `HostedayNotificationResponse` implementing `MapMixin` for seamless type safety and backwards-compatible key-value access.
- **Enhanced Realtime Presence**: Added `listenPresenceMembersList` callback to simplify tracking presence member lists alongside join and leave events.
- **Dynamic Channel Authorization**: Automatically injects dynamic authentication headers (`X-Api-Token` and `Authorization: Bearer <token>`) during private and presence channel authorization requests.

### Improved
- Cleaned root package structure from project-specific configuration files.
- Default path resolution: automatic resolution of standard HosteDay endpoints (`/api/jobs`, `/api/broadcasting/auth-manual`, `/api/notifications/devices/*`).
- Upgraded documentation and test suites with 100% test coverage.

## 2.3.1

### Added
- **Native Dart Configuration**: Adopted `lib/hosteday_config.dart` for direct, compile-time type-safe configuration.
- **HosteDay CLI Integration**: Full compatibility with automated CLI project cloning and provisioning (`setup.sh --clone`).
- **Live Bidding Radar Feature Module**: Added a pluggable, zero-impact architecture module (`lib/features/live_bidding/`) showcasing:
  - Real-time client-to-client events using WebSockets Whisper (`client-new-bid`).
  - Presence Channels with live participant tracking (`here`, `joining`, `leaving`).
  - Private Channels for individual outbid alerts and user-specific events.
  - Public Channels for global auction status.
- **Rich Push Notifications (FCM v1)**: Support for FCM v1 rich payloads, actions, and deep link routing.

### Security & Tooling
- **Secrets Sanitization**: Fully isolated tenant credentials and Firebase configurations from sample code into ignored local environments.
- Automated scripts for restoring and sanitizing development secrets.

## 2.3.0

- Add `HostedayClient.index()` returning `HostedayPage` with records and pagination metadata.
- Add `HostedayClient.show()` returning the unwrapped record.
- Validate resource response envelopes and preserve server error details and original field values.
- Keep raw `get()` behavior unchanged and reuse existing request routing, authentication, headers, and timeouts.
- Update the posts example and document search, pagination, and error handling.
- Add regression coverage for resource reads, malformed responses, pagination, and compatibility.

## 2.2.1 - 2026-11-06

- Template-ready starter configuration and automated CLI setup

## 2.2.0

- Adopt Hosteday names throughout the SDK and example; retain deprecated old APIs.
- Centralize API, host, static-page, and storage URL resolution.
- Automatically prefix REST resources with /api, without repeating existing prefixes.
- Add host, apiBaseUrl, staticPages, storageUrl, and initializeFromAsset APIs.
- Permit complete resource paths without an id argument on PUT/PATCH/DELETE.
- Add injectable HTTP transport to the composed client.
- Keep null optional keys compatible with REST-only generated applications.
- Preserve status/raw body on invalid JSON and useful network/timeout messages.
- Preserve auth validation details; correct profile update and event auth behavior.
- Add a live API explorer, rewrite documentation, and expand regression tests.
- Document URL/realtime behavior changes and environment-limited verification.

## 2.1.4 - 2026-07-26

### Added

* Added `Hosteday.auth.deleteUser()` to permanently delete the authenticated user.
* The local authentication session and stored access token are cleared automatically after
  successful account deletion.
