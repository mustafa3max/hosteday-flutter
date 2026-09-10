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