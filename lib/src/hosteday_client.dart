import 'auth/hosteday_token_provider.dart';
import 'config/hosteday_config.dart';
import 'http/hosteday_http_client.dart';
import 'realtime/hosteday_realtime_client.dart';

/// A high-level client for interacting with the HosteDay API.
///
/// The client provides convenient methods for sending HTTP requests and
/// accessing real-time functionality through [http] and [realtime].
class HosteDayClient {
/// The configuration used to connect to the HosteDay services.
final HosteDayConfig config;

/// The optional provider used to retrieve authentication tokens for requests.
final HosteDayTokenProvider? tokenProvider;

/// The HTTP client responsible for executing API requests.
late final HosteDayHttpClient http;

/// The real-time client responsible for managing live connections.
late final HosteDayRealtimeClient realtime;

/// Creates a [HosteDayClient] using the provided [config].
///
/// The optional [tokenProvider] is passed to the HTTP and real-time clients
/// to support authenticated requests and connections.
HosteDayClient({required this.config, this.tokenProvider}) {
http = HosteDayHttpClient(config: config, tokenProvider: tokenProvider);

realtime = HosteDayRealtimeClient(
config: config,
tokenProvider: tokenProvider,
);
}

/// Sends an HTTP request to the HosteDay API.
///
/// The [method] defines the HTTP method to use, such as `GET`, `POST`, or
/// `DELETE`. The [path] identifies the target API endpoint.
///
/// Provide [body] when the request requires a JSON payload. Set [withAuth]
/// to `true` when the request should include authentication credentials.
/// Additional request headers may be supplied through [headers].
///
/// Returns the decoded response payload as a map.
Future<Map<String, dynamic>> request({
required String method,
required String path,
Map<String, dynamic>? body,
bool withAuth = false,
Map<String, String>? headers,
}) {
return http.request(
method: method,
path: path,
body: body,
withAuth: withAuth,
headers: headers,
);
}

/// Sends a `GET` request to the specified API [path].
///
/// Set [withAuth] to `true` to include authentication credentials.
/// Additional HTTP headers can be provided through [headers].
///
/// Returns the decoded response payload as a map.
Future<Map<String, dynamic>> get(
String path, {
bool withAuth = false,
Map<String, String>? headers,
}) {
return request(
method: 'GET',
path: path,
withAuth: withAuth,
headers: headers,
);
}

/// Sends a `POST` request to the specified API [path].
///
/// The optional [body] is sent as the request payload. Set [withAuth] to
/// `true` to include authentication credentials. Additional HTTP headers
/// can be provided through [headers].
///
/// Returns the decoded response payload as a map.
Future<Map<String, dynamic>> post(
String path, {
Map<String, dynamic>? body,
bool withAuth = false,
Map<String, String>? headers,
}) {
return request(
method: 'POST',
path: path,
body: body,
withAuth: withAuth,
headers: headers,
);
}

/// Sends a `PUT` request to the specified API [path].
///
/// The optional [body] is sent as the request payload. Set [withAuth] to
/// `true` to include authentication credentials. Additional HTTP headers
/// can be provided through [headers].
///
/// Returns the decoded response payload as a map.
Future<Map<String, dynamic>> put(
String path, {
Map<String, dynamic>? body,
bool withAuth = false,
Map<String, String>? headers,
}) {
return request(
method: 'PUT',
path: path,
body: body,
withAuth: withAuth,
headers: headers,
);
}

/// Sends a `PATCH` request to the specified API [path].
///
/// The optional [body] is sent as the request payload. Set [withAuth] to
/// `true` to include authentication credentials. Additional HTTP headers
/// can be provided through [headers].
///
/// Returns the decoded response payload as a map.
Future<Map<String, dynamic>> patch(
String path, {
Map<String, dynamic>? body,
bool withAuth = false,
Map<String, String>? headers,
}) {
return request(
method: 'PATCH',
path: path,
body: body,
withAuth: withAuth,
headers: headers,
);
}

/// Sends a `DELETE` request to the specified API [path].
///
/// The optional [body] is sent as the request payload. Set [withAuth] to
/// `true` to include authentication credentials. Additional HTTP headers
/// can be provided through [headers].
///
/// Returns the decoded response payload as a map.
Future<Map<String, dynamic>> delete(
String path, {
Map<String, dynamic>? body,
bool withAuth = false,
Map<String, String>? headers,
}) {
return request(
method: 'DELETE',
path: path,
body: body,
withAuth: withAuth,
headers: headers,
);
}

/// Releases resources used by the HTTP and real-time clients.
///
/// This disconnects the real-time client before closing the HTTP client.
Future<void> dispose() async {
await realtime.disconnect();
http.close();
}
}
