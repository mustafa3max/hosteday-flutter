# Verification status

Prepared on 2026-09-10. No Flutter/Dart test pass is claimed.

| Command | Result |
| --- | --- |
| `dart format lib test example/lib example/test` | Blocked: `dart` executable is not installed in this environment. |
| `dart analyze` | Blocked: `dart` executable is not installed in this environment. |
| `dart test` | Blocked: `dart` executable is not installed in this environment. |
| `flutter analyze` | Blocked: `flutter` executable is not installed in this environment. |
| `flutter test` | Blocked: `flutter` executable is not installed in this environment. |

The official Flutter SDK download endpoint was attempted but was unreachable
from this environment. No SDK or dependency stubs were substituted.

Static source review checked local import/export paths, canonical/legacy names,
ZIP content integrity, and the correspondence of documentation with signatures.
These checks do not replace the Dart analyzer or Flutter runtime tests.

The added tests cover every HTTP verb, prefix normalization, query/filter values,
tokens, external-origin rejection, static/storage links, optional runtime fields,
legacy API forwarding, network/JSON/HTTP errors, and publishing auth policy.

Run `bash tool/verify.sh` in a Flutter-enabled environment before releasing.
Use `flutter test` for this Flutter-dependent suite. Standalone `dart test` is
not the appropriate runner for tests importing flutter_test. No live service,
browser Network panel, CORS, Android, iOS, or Web build was executed here.
