## 2.1.2 - 2026-07-17

### Added

* Added first-class resource URL parameters to `HosteDayClient` so developers can pass values
  without manually writing backend query names.
* Added optional `id`, `search`, `relationField`, and `relationValue` support to GET requests.
* Added `id`, `relationField`, and `relationValue` support to PUT, PATCH, and DELETE requests.
* Added automatic conversion of `relationField` and `relationValue` to `relation_field` and
  `relation_value` in request URLs.
* Added automatic resource ID appending, converting a path such as `/posts` with `id: 12` to
  `/posts/12`.

### Changed

* Updated `HosteDay.auth.updateProfile()` to accept a named `name` parameter and currently support
  updating the authenticated user's name only, with room for additional profile fields in future
  versions.
* Made `HosteDayClient` the public facade for HTTP requests, authentication, and realtime services.
* Made `HosteDayHttpClient` an internal implementation detail instead of requiring applications to
  use it directly.
* Updated custom API requests to default to `withAuth: false`; protected endpoints must explicitly
  use `withAuth: true`.
* Updated URL construction to omit null parameters and safely encode all path and query values.
* Clarified that the project API key and authenticated user bearer token are separate credentials.

### Documentation

* Updated CRUD examples for index, show, create, update, partial update, and delete operations.
* Documented passing `user_id` inside POST, PUT, and PATCH request bodies.
* Documented public and protected API request behavior and common `401 Unauthenticated` causes.
* Updated the example application structure to separate posts index, show, create, update, and
  delete responsibilities.
