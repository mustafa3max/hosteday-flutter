## 2.1.0 - 2026-07-13

### Added

* Added `HosteDay.auth.updateAvatar()` for uploading the authenticated user's profile image from raw
  bytes.
* Added automatic Base64 encoding for avatar upload requests.
* Added avatar extension validation for `jpg`, `jpeg`, `png`, and `webp`.
* Added `HosteDayUser.photoUrl` for accessing the user's profile image.
* Added `HosteDayUser.avatarUrl` as an alias for `photoUrl`.
* Added avatar parsing support for `avatar_url`, `avatarUrl`, `avatar`, `photo_url`, `photoUrl`,
  `image`, `image_url`, and `imageUrl`.
* Added automatic current-user and persisted-session updates after a successful avatar upload.
* Added an avatar upload example using `image_picker`.
* Added Android, iOS, and Web image picker configuration documentation.

### Changed

* Updated the profile example to display, select, upload, and refresh the authenticated user's
  avatar.
* Updated user documentation to use `photoUrl` and `avatarUrl`.
* Updated backend response examples to return complete HTTPS avatar URLs.
* Improved README and example Dart code formatting and alignment.
* Updated the structured example and Quick Experience documentation with avatar upload support.

### Fixed

* Fixed inconsistent handling of avatar fields returned by Laravel APIs.
* Fixed profile examples not refreshing after a successful avatar upload.
* Fixed documentation examples that used relative avatar paths directly instead of complete HTTPS
  URLs.
