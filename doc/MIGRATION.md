# Migration to 2.2.0

- `Hosteday` is canonical. All configuration is loaded exclusively from
  `assets/hosteday_config.json` via `await Hosteday.initializeApp()`.
  Existing session keys, project option keys, package names, domains, and
  protocol headers are unchanged.
- Use `HostedayOptionKeys` for option key constants.
- `Hosteday.client.staticPages['info']` is the supported page API. `static` is
  reserved in Dart and cannot be used as this property name.
- Resource paths now automatically receive `/api`. Existing `/api/products`
  paths still work. Code intentionally requesting non-API root routes through
  the SDK must move to an appropriate public URL/transport. This is a behavioral
  change even though source compatibility is preserved.
- An API override with a path uses that path as the exact API prefix; an
  origin-only override receives `/api`. `client.host` always uses the project
  origin.
- High-level mutation auth defaults stay true; low-level HTTP defaults stay
  false. Public publishing now uses false; private/presence publishing uses true.
- `put`, `patch`, and `delete` accept an omitted `id` for an already complete
  resource path. Existing calls with `id` continue to append it.
- `updateProfile` no longer appends the erroneous `/0` to `/api/user`.
- Realtime now requires an explicit host and app key when connecting. There is
  no implicit project-domain fallback. REST does not require either setting.
- Missing or invalid `assets/hosteday_config.json` throws `HostedayException`;
  uninitialized/repeated initialization throws `StateError`.
- Foreign-origin absolute REST URLs are rejected before credentials are read.
  Media URLs may use an external HTTP(S) CDN. Static pages require one slug.

## App Builder

Place the generated configuration file at `assets/hosteday_config.json`,
register it under `flutter.assets` in `pubspec.yaml`, and initialize with
`await Hosteday.initializeApp()`. Generate
`Hosteday.client.get('/products', search: search, withAuth: false)`.

This archive contains the Flutter package and its example, not the separate
App Builder Engine repository. No engine code or deployed backend was changed.
