import 'dart:async';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';

import '../auth/hosteday_token_provider.dart';
import '../config/hosteday_config.dart';
import '../exceptions/hosteday_exception.dart';
import 'hosteday_realtime_event.dart';

typedef HosteDayRealtimeCallback = void Function(HosteDayRealtimeEvent event);

class HosteDayRealtimeClient {
  final HosteDayConfig config;
  final HosteDayTokenProvider? tokenProvider;

  PusherChannelsClient? _client;

  final List<Channel> _channels = <Channel>[];
  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];

  HosteDayRealtimeClient({required this.config, this.tokenProvider});

  PusherChannelsClient get client {
    final value = _client;

    if (value == null) {
      throw const HosteDayException(
        'Realtime client is not connected. Call connect() first.',
      );
    }

    return value;
  }

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

  Channel publicChannel(String channelName) {
    final channel = client.publicChannel(channelName);
    _channels.add(channel);
    return channel;
  }

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
