import 'dart:async';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';

import '../auth/hosteday_token_provider.dart';
import '../config/hosteday_config.dart';
import '../exceptions/hosteday_exception.dart';
import 'hosteday_realtime_event.dart';

/// A callback invoked when a HosteDay real-time event is received.
///
/// The [event] contains the event name, channel name, normalized payload,
/// and the original raw event data when available.
typedef HosteDayRealtimeCallback = void Function(HosteDayRealtimeEvent event);

/// Manages real-time connections, channels, and event subscriptions for HosteDay.
///
/// Use this client to connect to the configured Pusher-compatible real-time
/// service, subscribe to public or private channels, and receive events through
/// [listenPublic] or [listenPrivate].
class HosteDayRealtimeClient {
/// The configuration used to establish the real-time connection.
final HosteDayConfig config;

/// The optional provider used to retrieve authentication tokens.
///
/// A token is required when subscribing to private channels.
final HosteDayTokenProvider? tokenProvider;

PusherChannelsClient? _client;

final List<Channel> _channels = <Channel>[];
final List<StreamSubscription<dynamic>> _subscriptions =
<StreamSubscription<dynamic>>[];

/// Creates a real-time client using the specified [config].
///
/// The optional [tokenProvider] is used to authorize private-channel
/// subscriptions.
HosteDayRealtimeClient({required this.config, this.tokenProvider});

/// The active Pusher channels client.
///
/// Throws a [HosteDayException] when [connect] has not been called or after
/// the client has been disconnected.
PusherChannelsClient get client {
final value = _client;

if (value == null) {
throw const HosteDayException(
'Realtime client is not connected. Call connect() first.',
);
}

return value;
}

/// Establishes a connection to the configured real-time service.
///
/// This initializes the underlying Pusher-compatible client using the
/// real-time host, key, and port defined in [config].
Future<void> connect() async {
final options = PusherChannelsOptions.fromHost(
scheme: "wss",
host: config.realtimeHost,
key: config.pusherKey,
port: config.realtimePort,
shouldSupplyMetadataQueries: true,
metadata: PusherChannelsOptionsMetadata.byDefault(),
);

_client = PusherChannelsClient.websocket(
options: options,
connectionErrorHandler: (exception, trace, refresh) {
refresh();
},
minimumReconnectDelayDuration: const Duration(seconds: 1),
defaultActivityDuration: const Duration(seconds: 120),
waitForPongDuration: const Duration(seconds: 30),
);

client.connect();
}

/// Creates and tracks a subscription channel for the public [channelName].
///
/// The client must be connected before calling this method.
Channel publicChannel(String channelName) {
final channel = client.publicChannel(channelName);
_channels.add(channel);
return channel;
}

/// Creates and tracks an authorized private channel for [channelName].
///
/// A valid token must be available through [tokenProvider]. The channel name
/// is automatically prefixed with `private-` when it does not already have
/// that prefix.
///
/// Throws a [HosteDayException] when no authentication token is available.
Future<Channel> privateChannel(String channelName) async {
final token = await tokenProvider?.getToken();

if (token == null || token.isEmpty) {
throw const HosteDayException(
'Missing authentication token for private channel.',
);
}

final normalizedChannel = _normalizePrivateChannelName(channelName);

final channel = client.privateChannel(
normalizedChannel,
authorizationDelegate:
EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
authorizationEndpoint: config.uri(config.broadcastingAuthPath),
headers: {
'Accept': 'application/json',
'Authorization': 'Bearer $token',
},
),
);

_channels.add(channel);
return channel;
}

/// Subscribes to an [event] on a public [channel].
///
/// Received events are converted to [HosteDayRealtimeEvent] instances and
/// passed to [onEvent]. The returned subscription can be used to manage the
/// individual event listener.
StreamSubscription<dynamic> listenPublic({
required String channel,
required String event,
required HosteDayRealtimeCallback onEvent,
}) {
final public = publicChannel(channel);

final subscription = public.bind(event).listen((rawEvent) {
onEvent(
HosteDayRealtimeEvent.fromRaw(
name: event,
channelName: channel,
data: rawEvent.data,
raw: rawEvent,
),
);
});

_subscriptions.add(subscription);
public.subscribe();

return subscription;
}

/// Subscribes to an [event] on a private [channel].
///
/// The channel is authorized using the configured token provider. Received
/// events are converted to [HosteDayRealtimeEvent] instances and passed to
/// [onEvent]. The returned subscription can be used to manage the individual
/// event listener.
///
/// Throws a [HosteDayException] when an authentication token is unavailable.
Future<StreamSubscription<dynamic>> listenPrivate({
required String channel,
required String event,
required HosteDayRealtimeCallback onEvent,
}) async {
final private = await privateChannel(channel);

final subscription = private.bind(event).listen((rawEvent) {
onEvent(
HosteDayRealtimeEvent.fromRaw(
name: event,
channelName: _normalizePrivateChannelName(channel),
data: rawEvent.data,
raw: rawEvent,
),
);
});

_subscriptions.add(subscription);
private.subscribe();

return subscription;
}

String _normalizePrivateChannelName(String channel) {
if (channel.startsWith('private-')) {
return channel;
}

return 'private-$channel';
}

/// Cancels all active subscriptions and disconnects from real-time channels.
///
/// This method unsubscribes tracked channels, disposes the underlying client,
/// and clears internal connection state.
Future<void> disconnect() async {
for (final subscription in _subscriptions) {
await subscription.cancel();
}

_subscriptions.clear();

for (final channel in _channels) {
channel.unsubscribe();
}

_channels.clear();

_client?.dispose();
_client = null;
}
}