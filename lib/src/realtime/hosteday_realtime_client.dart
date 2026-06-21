import 'dart:async';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';

import '../auth/hosteday_token_provider.dart';
import '../config/hosteday_config.dart';
import '../exceptions/hosteday_exception.dart';
import 'hosteday_channel_type.dart';
import 'hosteday_realtime_event.dart';

/// A callback invoked when a HosteDay real-time event is received.
typedef HosteDayRealtimeCallback = void Function(HosteDayRealtimeEvent event);

/// Manages HosteDay real-time connections, channels, and event subscriptions.
///
/// Supported channel types:
/// - Public
/// - Private
/// - Presence
/// - Private encrypted
class HosteDayRealtimeClient {
  /// The configuration used to establish the real-time connection.
  final HosteDayConfig config;

  /// The provider used to retrieve the authenticated user's token.
  ///
  /// A token is required for private, presence, and private encrypted channels.
  final HosteDayTokenProvider? tokenProvider;

  PusherChannelsClient? _client;

  /// Stores channels by their normalized Pusher channel names.
  ///
  /// Examples:
  /// - tenant.chat.room.1
  /// - private-tenant.orders.1
  /// - presence-tenant.chat.room.1
  final Map<String, Channel> _channels = <String, Channel>{};

  /// Stores event listeners by normalized channel name.
  ///
  /// This allows listeners to be cancelled when only one channel is
  /// unsubscribed.
  final Map<String, List<StreamSubscription<dynamic>>> _subscriptions =
      <String, List<StreamSubscription<dynamic>>>{};

  StreamSubscription<dynamic>? _connectionSubscription;

  /// Creates a real-time client using the specified [config].
  HosteDayRealtimeClient({
    required this.config,
    this.tokenProvider,
  });

  /// Returns the active Pusher-compatible client.
  ///
  /// Throws [HosteDayException] when [connect] has not been called or after
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

  /// Returns whether the real-time client has been initialized.
  bool get isConnected => _client != null;

  /// Connects to the configured HosteDay Pusher-compatible WebSocket server.
  ///
  /// Example generated URL:
  /// wss://ws3.hosteday.com:443/app/YOUR_PUSHER_KEY
  ///
  /// The package adds the `/app/{pusherKey}` path automatically when
  /// [PusherChannelsOptions.fromHost] is used.
  Future<void> connect() async {
    if (_client != null) {
      return;
    }

    if (config.realtimeHost.trim().isEmpty) {
      throw const HosteDayException(
        'Missing realtime host. Configure realtime_host or project_domain.',
      );
    }

    if (config.pusherKey.trim().isEmpty) {
      throw const HosteDayException(
        'Missing Pusher key. Configure pusher_key before connecting realtime.',
      );
    }

    final options = PusherChannelsOptions.fromHost(
      host: config.realtimeHost,
      key: config.pusherKey,
      port: 443,
      scheme: "wss",
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

    /// Re-subscribes tracked channels after a reconnect.
    _connectionSubscription = client.onConnectionEstablished.listen((_) {
      for (final channel in _channels.values) {
        channel.subscribeIfNotUnsubscribed();
      }
    });

    client.connect();
  }

  /// Creates or returns a tracked public channel.
  ///
  /// Public channels do not require authentication.
  Channel publicChannel(String channelName) {
    final normalizedChannel = _normalizePublicChannelName(channelName);

    final existingChannel = _channels[normalizedChannel];

    if (existingChannel != null) {
      return existingChannel;
    }

    final channel = client.publicChannel(normalizedChannel);

    _channels[normalizedChannel] = channel;

    return channel;
  }

  /// Creates or returns a tracked private channel.
  ///
  /// A valid user token is required.
  Future<Channel> privateChannel(String channelName) async {
    final normalizedChannel = _normalizePrivateChannelName(channelName);

    final existingChannel = _channels[normalizedChannel];

    if (existingChannel != null) {
      return existingChannel;
    }

    final token = await _requiredToken(
      channelType: 'private channel',
    );

    final channel = client.privateChannel(
      normalizedChannel,
      authorizationDelegate:
          EndpointAuthorizableChannelTokenAuthorizationDelegate
              .forPrivateChannel(
        authorizationEndpoint: config.uri(config.broadcastingAuthPath),
        headers: _authorizationHeaders(token),
      ),
    );

    _channels[normalizedChannel] = channel;

    return channel;
  }

  /// Creates or returns a tracked presence channel.
  ///
  /// The `presence-` prefix is added automatically when needed.
  Future<PresenceChannel> presenceChannel(String channelName) async {
    final normalizedChannel = _normalizePresenceChannelName(channelName);

    final existingChannel = _channels[normalizedChannel];

    if (existingChannel != null) {
      if (existingChannel is PresenceChannel) {
        return existingChannel;
      }

      throw HosteDayException(
        'A different channel type is already registered for '
        '"$normalizedChannel".',
      );
    }

    final token = await _requiredToken(
      channelType: 'presence channel',
    );

    final channel = client.presenceChannel(
      normalizedChannel,
      authorizationDelegate:
          EndpointAuthorizableChannelTokenAuthorizationDelegate
              .forPresenceChannel(
        authorizationEndpoint: config.uri(config.broadcastingAuthPath),
        headers: _authorizationHeaders(token),
      ),
    );

    _channels[normalizedChannel] = channel;

    return channel;
  }

  /// Creates or returns a tracked private encrypted channel.
  ///
  /// The HosteDay backend must explicitly support private encrypted channels.
  Future<Channel> privateEncryptedChannel(String channelName) async {
    final normalizedChannel = _normalizePrivateEncryptedChannelName(
      channelName,
    );

    final existingChannel = _channels[normalizedChannel];

    if (existingChannel != null) {
      return existingChannel;
    }

    final token = await _requiredToken(
      channelType: 'private encrypted channel',
    );

    final channel = client.privateEncryptedChannel(
      normalizedChannel,
      authorizationDelegate:
          EndpointAuthorizableChannelTokenAuthorizationDelegate
              .forPrivateEncryptedChannel(
        authorizationEndpoint: config.uri(config.broadcastingAuthPath),
        headers: _authorizationHeaders(token),
      ),
    );

    _channels[normalizedChannel] = channel;

    return channel;
  }

  /// Creates or returns a channel according to [type].
  Future<Channel> channel(
    String channelName, {
    HosteDayChannelType type = HosteDayChannelType.public,
  }) async {
    switch (type) {
      case HosteDayChannelType.public:
        return publicChannel(channelName);

      case HosteDayChannelType.private:
        return privateChannel(channelName);

      case HosteDayChannelType.presence:
        return presenceChannel(channelName);

      case HosteDayChannelType.privateEncrypted:
        return privateEncryptedChannel(channelName);
    }
  }

  /// Listens to [event] on a channel of the specified [type].
  ///
  /// This is the preferred unified method for all channel types.
  Future<StreamSubscription<dynamic>> listen({
    required String channel,
    required String event,
    required HosteDayRealtimeCallback onEvent,
    HosteDayChannelType type = HosteDayChannelType.public,
  }) async {
    final normalizedChannel = _normalizeChannelName(
      channel,
      type,
    );

    final realtimeChannel = await this.channel(
      channel,
      type: type,
    );

    final subscription = realtimeChannel.bind(event).listen((rawEvent) {
      onEvent(
        HosteDayRealtimeEvent.fromRaw(
          name: event,
          channelName: normalizedChannel,
          data: rawEvent.data,
          raw: rawEvent,
        ),
      );
    });

    _trackSubscription(normalizedChannel, subscription);

    /// This sends the Pusher `pusher:subscribe` command automatically.
    realtimeChannel.subscribeIfNotUnsubscribed();

    return subscription;
  }

  /// Listens to an event on a public channel.
  Future<StreamSubscription<dynamic>> listenPublic({
    required String channel,
    required String event,
    required HosteDayRealtimeCallback onEvent,
  }) {
    return listen(
      channel: channel,
      event: event,
      onEvent: onEvent,
      type: HosteDayChannelType.public,
    );
  }

  /// Listens to an event on a private channel.
  Future<StreamSubscription<dynamic>> listenPrivate({
    required String channel,
    required String event,
    required HosteDayRealtimeCallback onEvent,
  }) {
    return listen(
      channel: channel,
      event: event,
      onEvent: onEvent,
      type: HosteDayChannelType.private,
    );
  }

  /// Listens to an event on a presence channel.
  Future<StreamSubscription<dynamic>> listenPresence({
    required String channel,
    required String event,
    required HosteDayRealtimeCallback onEvent,
  }) {
    return listen(
      channel: channel,
      event: event,
      onEvent: onEvent,
      type: HosteDayChannelType.presence,
    );
  }

  /// Listens to an event on a private encrypted channel.
  Future<StreamSubscription<dynamic>> listenPrivateEncrypted({
    required String channel,
    required String event,
    required HosteDayRealtimeCallback onEvent,
  }) {
    return listen(
      channel: channel,
      event: event,
      onEvent: onEvent,
      type: HosteDayChannelType.privateEncrypted,
    );
  }

  /// Listens for new members joining a presence channel.
  Future<StreamSubscription<dynamic>> listenPresenceMemberAdded({
    required String channel,
    required HosteDayRealtimeCallback onEvent,
  }) async {
    final normalizedChannel = _normalizePresenceChannelName(channel);

    final presence = await presenceChannel(channel);

    final subscription = presence.whenMemberAdded().listen((rawEvent) {
      onEvent(
        HosteDayRealtimeEvent.fromRaw(
          name: 'pusher:member_added',
          channelName: normalizedChannel,
          data: rawEvent.data,
          raw: rawEvent,
        ),
      );
    });

    _trackSubscription(normalizedChannel, subscription);

    presence.subscribeIfNotUnsubscribed();

    return subscription;
  }

  /// Listens for members leaving a presence channel.
  Future<StreamSubscription<dynamic>> listenPresenceMemberRemoved({
    required String channel,
    required HosteDayRealtimeCallback onEvent,
  }) async {
    final normalizedChannel = _normalizePresenceChannelName(channel);

    final presence = await presenceChannel(channel);

    final subscription = presence.whenMemberRemoved().listen((rawEvent) {
      onEvent(
        HosteDayRealtimeEvent.fromRaw(
          name: 'pusher:member_removed',
          channelName: normalizedChannel,
          data: rawEvent.data,
          raw: rawEvent,
        ),
      );
    });

    _trackSubscription(normalizedChannel, subscription);

    presence.subscribeIfNotUnsubscribed();

    return subscription;
  }

  /// Returns a tracked channel when it exists.
  Channel? getChannel(
    String channelName, {
    HosteDayChannelType type = HosteDayChannelType.public,
  }) {
    final normalizedChannel = _normalizeChannelName(
      channelName,
      type,
    );

    return _channels[normalizedChannel];
  }

  /// Unsubscribes from one channel without closing the WebSocket connection.
  ///
  /// All listeners attached through this client for that channel are cancelled.
  Future<void> unsubscribe(
    String channelName, {
    HosteDayChannelType type = HosteDayChannelType.public,
  }) async {
    final normalizedChannel = _normalizeChannelName(
      channelName,
      type,
    );

    final subscriptions = _subscriptions.remove(normalizedChannel);

    if (subscriptions != null) {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    }

    final channel = _channels.remove(normalizedChannel);

    if (channel != null) {
      channel.unsubscribe();
    }
  }

  /// Cancels all listeners, unsubscribes channels, and disconnects WebSocket.
  Future<void> disconnect() async {
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    for (final subscriptions in _subscriptions.values) {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    }

    _subscriptions.clear();

    for (final channel in _channels.values) {
      channel.unsubscribe();
    }

    _channels.clear();

    _client?.dispose();
    _client = null;
  }

  void _trackSubscription(
    String channelName,
    StreamSubscription<dynamic> subscription,
  ) {
    final channelSubscriptions = _subscriptions.putIfAbsent(
      channelName,
      () => <StreamSubscription<dynamic>>[],
    );

    channelSubscriptions.add(subscription);
  }

  Future<String> _requiredToken({
    required String channelType,
  }) async {
    final token = await tokenProvider?.getToken();

    if (token == null || token.trim().isEmpty) {
      throw HosteDayException(
        'Missing authentication token for $channelType.',
      );
    }

    return token.trim();
  }

  Map<String, String> _authorizationHeaders(String token) {
    return <String, String>{
      'Accept': 'application/json',
      ...config.defaultHeaders,
      'Authorization': 'Bearer $token',
    };
  }

  String _normalizeChannelName(
    String channel,
    HosteDayChannelType type,
  ) {
    switch (type) {
      case HosteDayChannelType.public:
        return _normalizePublicChannelName(channel);

      case HosteDayChannelType.private:
        return _normalizePrivateChannelName(channel);

      case HosteDayChannelType.presence:
        return _normalizePresenceChannelName(channel);

      case HosteDayChannelType.privateEncrypted:
        return _normalizePrivateEncryptedChannelName(channel);
    }
  }

  String _normalizePublicChannelName(String channel) {
    final normalized = _requiredChannelName(channel);

    if (normalized.startsWith('private-') ||
        normalized.startsWith('presence-')) {
      throw ArgumentError.value(
        channel,
        'channel',
        'A public channel cannot start with private- or presence-.',
      );
    }

    return normalized;
  }

  String _normalizePrivateChannelName(String channel) {
    final normalized = _requiredChannelName(channel);

    if (normalized.startsWith('presence-')) {
      throw ArgumentError.value(
        channel,
        'channel',
        'Use HosteDayChannelType.presence for presence channels.',
      );
    }

    if (normalized.startsWith('private-encrypted-')) {
      throw ArgumentError.value(
        channel,
        'channel',
        'Use HosteDayChannelType.privateEncrypted for encrypted channels.',
      );
    }

    if (normalized.startsWith('private-')) {
      return normalized;
    }

    return 'private-$normalized';
  }

  String _normalizePresenceChannelName(String channel) {
    final normalized = _requiredChannelName(channel);

    if (normalized.startsWith('private-')) {
      throw ArgumentError.value(
        channel,
        'channel',
        'Remove the private- prefix when using a presence channel.',
      );
    }

    if (normalized.startsWith('presence-')) {
      return normalized;
    }

    return 'presence-$normalized';
  }

  String _normalizePrivateEncryptedChannelName(String channel) {
    final normalized = _requiredChannelName(channel);

    if (normalized.startsWith('presence-')) {
      throw ArgumentError.value(
        channel,
        'channel',
        'Presence channels cannot use private encrypted mode.',
      );
    }

    if (normalized.startsWith('private-encrypted-')) {
      return normalized;
    }

    if (normalized.startsWith('private-')) {
      return 'private-encrypted-${normalized.substring('private-'.length)}';
    }

    return 'private-encrypted-$normalized';
  }

  String _requiredChannelName(String channel) {
    final normalized = channel.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        channel,
        'channel',
        'A channel name is required.',
      );
    }

    return normalized;
  }
}
