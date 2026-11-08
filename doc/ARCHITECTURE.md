# Package architecture and review

| Area | Responsibility |
| --- | --- |
| `hosteday.dart` | Global initialization, optional runtime asset loading, lifecycle, old facade |
| `hosteday_client.dart` | Public SDK composition and convenience methods |
| `config/` | Typed connection values, option parsing, platform routes and project headers |
| `urls/` | One URL policy for API prefixes, origins, page slugs, and public media |
| `http/` | Injected transport, query/body encoding, user token lookup, status and JSON handling |
| `auth/` | User/session models, auth flows, persistence, token provider composition |
| `realtime/` | Optional Pusher-compatible connection and channel subscriptions |
| `exceptions/` | Structured HTTP/validation errors and developer diagnostics |
| `example/` | Live request explorer and account/posts/Realtime screens |
| `test/` | Deterministic mocked requests, URL boundaries, runtime initialization and compatibility |

## Findings addressed

Previously `config.uri` concatenated the base URL and path, so engine-generated
`/products` requests missed `/api`. There were no public host/page/storage helpers.
The canonical spelling was reversed, with the requested name already deprecated.
Realtime event publishing applied user authentication in the opposite direction
to its documentation. Profile updates appended a synthetic ID. Invalid JSON
responses hid the HTTP status, and auth conversion discarded validation details.
The example bypassed its account gate and contained an unrelated counter test.

The URL resolver now owns the prefix policy and public URL construction. The
existing query/filter implementation, storage abstractions, user models, and
Realtime channel implementation are retained. Transport injection enables real
public-client tests without backend access. No dependencies were added.

## Limits

The package builds URLs and interprets server responses; it does not create
backend tables, verify the existence of static pages, supply demo records, or
configure server CORS. Platform headers were preserved from the uploaded source;
no unpublished backend contract was inferred for status codes 430–433.
Android/iOS/Web build and live service checks still need a Flutter-enabled runner
and an actual project configuration. See VERIFICATION.md for what ran here.
