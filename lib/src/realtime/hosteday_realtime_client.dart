import 'dart:async';
import 'dart:convert';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../auth/hosteday_auth_storage.dart';
import '../auth/hosteday_token_provider.dart';
import '../config/hosteday_config.dart';
import '../exceptions/hosteday_exception.dart';
import 'hosteday_channel_authorization_delegate.dart';
import 'hosteday_channel_type.dart';
import 'hosteday_realtime_event.dart';

/// A callback invoked when a Hosteday realtime event is received.
typedef HostedayRealtimeCallback = void Function(
  HostedayRealtimeEvent event,
);

/// Manages Hosteday realtime connections, channels, and event subscriptions.
///
/// Supported channel types:
/// - Public
/// - Private
/// - Presence
/// - Private encrypted
class HostedayRealtimeClient {
  /// The configuration used to establish the realtime connection.
  final HostedayConfig config;

  /// The provider used to retrieve the authenticated user's token.
  ///
  /// A token is required for private, presence, and private encrypted channels.
  final HostedayTokenProvider? tokenProvider;

  /// Optional storage used to retrieve active auth tokens.
  final HostedayAuthStorage? authStorage;

  /// Optional callback to build HTTP headers dynamically for channel authorization.
  final FutureOr<Map<String, String>> Function()? headersCallback;

  PusherChannelsClient? _client;

  /// Stores channels by their normalized Pusher channel names.
  ///
  /// Examples:
  /// - `tenant.chat.room.1`
  /// - `private-tenant.orders.1`
  /// - `presence-tenant.chat.room.1`
  final Map<String, Channel> _channels = <String, Channel>{};

  /// Stores event listeners by normalized channel name.
  ///
  /// This allows listeners to be cancelled when only one channel is
  /// unsubscribed.
  final Map<String, List<StreamSubscription<dynamic>>> _subscriptions =
      <String, List<StreamSubscription<dynamic>>>{};

  StreamSubscription<dynamic>? _connectionSubscription;
  StreamSubscription<dynamic>? _lifecycleSubscription;

  bool _isConnected = false;
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();

  /// Creates a realtime client using the specified [config].
  HostedayRealtimeClient({
    required this.config,
    this.tokenProvider,
    this.authStorage,
    this.headersCallback,
  });

  /// Returns the active Pusher-compatible client.
  ///
  /// Throws [HostedayException] when [connect] has not been called or after
  /// the client has been disconnected.
  PusherChannelsClient get client {
    final value = _client;

    if (value == null) {
      throw const HostedayException(
        'Realtime client is not connected. Call connect() first.',
      );
    }

    return value;
  }

  /// Returns whether the realtime WebSocket connection is currently active and established.
  bool get isConnected => _isConnected;

  /// Stream of connection state changes (true = connected, false = disconnected).
  Stream<bool> get onConnectionStateChanged =>
      _connectionStateController.stream;

  /// Connects to the configured Hosteday Pusher-compatible WebSocket server.
  ///
  /// Example generated URL:
  /// `wss://ws3.hosteday.com:443/app/YOUR_PUSHER_KEY`
  ///
  /// The package adds the `/app/{pusherKey}` path automatically when
  /// [PusherChannelsOptions.fromHost] is used.
  Future<void> connect() async {
    if (_client != null) {
      return;
    }

    var realtimeHost = config.realtimeHost.trim();
    final pusherKey = config.pusherKey.trim();

    if (realtimeHost.isEmpty) {
      throw const HostedayException(
        'Missing realtime host. Configure realtime_host before connecting realtime.',
      );
    }

    // Automatically normalize legacy ws3 node if configured
    if (realtimeHost == 'ws3.hosteday.com') {
      realtimeHost = 'ws.hosteday.com';
    }

    if (pusherKey.isEmpty) {
      throw const HostedayException(
        'Missing Pusher key. Configure realtime_app_key before connecting realtime.',
      );
    }

    final options = PusherChannelsOptions.fromHost(
      host: realtimeHost,
      key: pusherKey,
      port: config.realtimePort,
      scheme: config.realtimeScheme,
      shouldSupplyMetadataQueries: true,
      metadata: PusherChannelsOptionsMetadata.byDefault(),
    );

    final realtimeClient = PusherChannelsClient.websocket(
      options: options,
      connectionErrorHandler: (exception, trace, refresh) {
        refresh();
      },
      minimumReconnectDelayDuration: const Duration(seconds: 1),
      defaultActivityDuration: const Duration(seconds: 120),
      waitForPongDuration: const Duration(seconds: 30),
    );

    _client = realtimeClient;

    /// Listens for connection state lifecycle changes.
    _lifecycleSubscription = realtimeClient.lifecycleStream.listen((state) {
      final isEstablished =
          state == PusherChannelsClientLifeCycleState.establishedConnection;
      if (_isConnected != isEstablished) {
        _isConnected = isEstablished;
        _connectionStateController.add(isEstablished);
      }
    });

    /// Re-subscribes tracked channels after a reconnect.
    _connectionSubscription =
        realtimeClient.onConnectionEstablished.listen((_) {
      for (final channel in _channels.values) {
        channel.subscribeIfNotUnsubscribed();
      }
    });

    realtimeClient.connect();
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

    final channel = client.privateChannel(
      normalizedChannel,
      authorizationDelegate:
          HostedayChannelAuthorizationDelegate.forPrivateChannel(
        authorizationEndpoint: config.uri(config.broadcastingAuthPath),
        headersBuilder: buildAuthorizationHeaders,
        parser: _parsePrivateAuthResponse,
        onAuthFailed: (exception, trace) {
          debugPrint(
            '[HostedayRealtimeClient] Private channel auth failed for '
            '"$normalizedChannel": $exception',
          );
        },
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

      throw HostedayException(
        'A different channel type is already registered for '
        '"$normalizedChannel".',
      );
    }

    final channel = client.presenceChannel(
      normalizedChannel,
      authorizationDelegate:
          HostedayChannelAuthorizationDelegate.forPresenceChannel(
        authorizationEndpoint: config.uri(config.broadcastingAuthPath),
        headersBuilder: buildAuthorizationHeaders,
        parser: _parsePresenceAuthResponse,
        onAuthFailed: (exception, trace) {
          debugPrint(
            '[HostedayRealtimeClient] Presence channel auth failed for '
            '"$normalizedChannel": $exception',
          );
        },
      ),
    );

    _channels[normalizedChannel] = channel;

    return channel;
  }

  /// Creates or returns a tracked private encrypted channel.
  ///
  /// The Hosteday backend must explicitly support private encrypted channels.
  Future<Channel> privateEncryptedChannel(String channelName) async {
    final normalizedChannel = _normalizePrivateEncryptedChannelName(
      channelName,
    );

    final existingChannel = _channels[normalizedChannel];

    if (existingChannel != null) {
      return existingChannel;
    }

    final channel = client.privateEncryptedChannel(
      normalizedChannel,
      authorizationDelegate:
          HostedayChannelAuthorizationDelegate.forPrivateEncryptedChannel(
        authorizationEndpoint: config.uri(config.broadcastingAuthPath),
        headersBuilder: buildAuthorizationHeaders,
        onAuthFailed: (exception, trace) {
          debugPrint(
            '[HostedayRealtimeClient] Private encrypted channel auth failed for '
            '"$normalizedChannel": $exception',
          );
        },
      ),
    );

    _channels[normalizedChannel] = channel;

    return channel;
  }

  /// Creates or returns a channel according to [type].
  Future<Channel> channel(
    String channelName, {
    HostedayChannelType type = HostedayChannelType.public,
  }) async {
    switch (type) {
      case HostedayChannelType.public:
        return publicChannel(channelName);

      case HostedayChannelType.private:
        return privateChannel(channelName);

      case HostedayChannelType.presence:
        return presenceChannel(channelName);

      case HostedayChannelType.privateEncrypted:
        return privateEncryptedChannel(channelName);
    }
  }

  /// Listens to [event] on a channel of the specified [type].
  ///
  /// This is the preferred unified method for all channel types.
  Future<StreamSubscription<dynamic>> listen({
    required String channel,
    required String event,
    required HostedayRealtimeCallback onEvent,
    HostedayChannelType type = HostedayChannelType.public,
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
        HostedayRealtimeEvent.fromRaw(
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
    required HostedayRealtimeCallback onEvent,
  }) {
    return listen(
      channel: channel,
      event: event,
      onEvent: onEvent,
      type: HostedayChannelType.public,
    );
  }

  /// Listens to an event on a private channel.
  Future<StreamSubscription<dynamic>> listenPrivate({
    required String channel,
    required String event,
    required HostedayRealtimeCallback onEvent,
  }) {
    return listen(
      channel: channel,
      event: event,
      onEvent: onEvent,
      type: HostedayChannelType.private,
    );
  }

  /// Listens to an event on a presence channel.
  Future<StreamSubscription<dynamic>> listenPresence({
    required String channel,
    required String event,
    required HostedayRealtimeCallback onEvent,
  }) {
    return listen(
      channel: channel,
      event: event,
      onEvent: onEvent,
      type: HostedayChannelType.presence,
    );
  }

  /// Listens to an event on a private encrypted channel.
  Future<StreamSubscription<dynamic>> listenPrivateEncrypted({
    required String channel,
    required String event,
    required HostedayRealtimeCallback onEvent,
  }) {
    return listen(
      channel: channel,
      event: event,
      onEvent: onEvent,
      type: HostedayChannelType.privateEncrypted,
    );
  }

  /// Listens for initial members already present in a presence channel ('here' / subscription_succeeded).
  Future<StreamSubscription<dynamic>> listenPresenceMembersList({
    required String channel,
    required HostedayRealtimeCallback onEvent,
  }) =>
      listenPresenceHere(channel: channel, onEvent: onEvent);

  /// Listens for initial members already present in a presence channel ('here' / subscription_succeeded).
  @Deprecated('Use listenPresenceMembersList instead.')
  Future<StreamSubscription<dynamic>> listenPresenceHere({
    required String channel,
    required HostedayRealtimeCallback onEvent,
  }) async {
    final normalizedChannel = _normalizePresenceChannelName(channel);

    final presence = await presenceChannel(channel);

    final subscription =
        presence.whenSubscriptionSucceeded().listen((rawEvent) {
      onEvent(
        HostedayRealtimeEvent.fromRaw(
          name: 'pusher:subscription_succeeded',
          channelName: normalizedChannel,
          data: rawEvent.data,
          raw: rawEvent,
        ),
      );
    });

    _trackSubscription(normalizedChannel, subscription);

    final currentMembers = presence.state?.members;
    if (presence.state?.status == ChannelStatus.subscribed &&
        currentMembers != null) {
      scheduleMicrotask(() {
        final hash = <String, dynamic>{};
        currentMembers.getAsMap().forEach((key, val) {
          hash[key] = val?.info ?? <String, dynamic>{'id': key};
        });
        onEvent(
          HostedayRealtimeEvent.fromRaw(
            name: 'pusher:subscription_succeeded',
            channelName: normalizedChannel,
            data: {
              'presence': {
                'count': currentMembers.membersCount,
                'ids': currentMembers.getAsMap().keys.toList(),
                'hash': hash,
              },
            },
          ),
        );
      });
    }

    presence.subscribeIfNotUnsubscribed();

    return subscription;
  }

  /// Listens for new members joining a presence channel.
  Future<StreamSubscription<dynamic>> listenPresenceMemberAdded({
    required String channel,
    required HostedayRealtimeCallback onEvent,
  }) async {
    final normalizedChannel = _normalizePresenceChannelName(channel);

    final presence = await presenceChannel(channel);

    final subscription = presence.whenMemberAdded().listen((rawEvent) {
      onEvent(
        HostedayRealtimeEvent.fromRaw(
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
    required HostedayRealtimeCallback onEvent,
  }) async {
    final normalizedChannel = _normalizePresenceChannelName(channel);

    final presence = await presenceChannel(channel);

    final subscription = presence.whenMemberRemoved().listen((rawEvent) {
      onEvent(
        HostedayRealtimeEvent.fromRaw(
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
    HostedayChannelType type = HostedayChannelType.public,
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
    HostedayChannelType type = HostedayChannelType.public,
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

    await _lifecycleSubscription?.cancel();
    _lifecycleSubscription = null;

    if (_isConnected) {
      _isConnected = false;
      _connectionStateController.add(false);
    }

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

  /// Asynchronously builds the dynamic authorization headers for broadcasting requests.
  ///
  /// Always returns:
  /// - `Accept: application/json`
  /// - `X-Api-Token: config.apiToken` (when configured)
  /// - `Authorization: Bearer $currentToken` (dynamically fetched from tokenProvider or authStorage)
  Future<Map<String, String>> buildAuthorizationHeaders() async {
    if (headersCallback != null) {
      return await headersCallback!();
    }

    String? currentToken = await tokenProvider?.getToken();
    if ((currentToken == null || currentToken.trim().isEmpty) &&
        authStorage != null) {
      currentToken =
          await authStorage!.read(HostedayAuthStorageKeys.accessToken);
      if (currentToken == null || currentToken.trim().isEmpty) {
        final session =
            await authStorage!.read(HostedayAuthStorageKeys.session);
        if (session != null && session.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(session);
            if (decoded is Map) {
              currentToken = decoded['access_token']?.toString();
            }
          } catch (_) {}
        }
      }
    }

    final cleanToken = currentToken?.trim();

    final headers = <String, String>{
      'Accept': 'application/json',
      ...config.defaultHeaders,
    };

    final apiToken = config.apiToken?.trim();
    if (apiToken != null && apiToken.isNotEmpty) {
      headers['X-Api-Token'] = apiToken;
      if (config.apiTokenHeader.isNotEmpty) {
        headers[config.apiTokenHeader] = apiToken;
      }
    }

    if (cleanToken != null && cleanToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $cleanToken';
    }

    return headers;
  }

  String _normalizeChannelName(
    String channel,
    HostedayChannelType type,
  ) {
    switch (type) {
      case HostedayChannelType.public:
        return _normalizePublicChannelName(channel);

      case HostedayChannelType.private:
        return _normalizePrivateChannelName(channel);

      case HostedayChannelType.presence:
        return _normalizePresenceChannelName(channel);

      case HostedayChannelType.privateEncrypted:
        return _normalizePrivateEncryptedChannelName(channel);
    }
  }

  String _normalizePublicChannelName(String channel) {
    final normalized = _requiredChannelName(channel);

    if (normalized.startsWith('private-') ||
        normalized.startsWith('presence-') ||
        normalized.startsWith('private-encrypted-')) {
      throw ArgumentError.value(
        channel,
        'channel',
        'A public channel cannot start with private-, presence-, or '
            'private-encrypted-.',
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
        'Use HostedayChannelType.presence for presence channels.',
      );
    }

    if (normalized.startsWith('private-encrypted-')) {
      throw ArgumentError.value(
        channel,
        'channel',
        'Use HostedayChannelType.privateEncrypted for encrypted channels.',
      );
    }

    if (normalized.startsWith('private-')) {
      return normalized;
    }

    return 'private-$normalized';
  }

  String _normalizePresenceChannelName(String channel) {
    final normalized = _requiredChannelName(channel);

    if (normalized.startsWith('private-') ||
        normalized.startsWith('private-encrypted-')) {
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

  static PrivateChannelAuthorizationData _parsePrivateAuthResponse(
    http.Response response,
  ) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const FormatException(
        'Invalid JSON returned by broadcasting auth endpoint',
      );
    }

    Map<dynamic, dynamic>? payload;
    if (decoded is Map) {
      if (decoded.containsKey('auth')) {
        payload = decoded;
      } else if (decoded['data'] is Map &&
          (decoded['data'] as Map).containsKey('auth')) {
        payload = decoded['data'] as Map;
      }
    }

    if (payload == null) {
      throw FormatException(
        'Broadcasting auth endpoint returned payload without "auth" key: '
        '${response.body}',
      );
    }

    final auth = payload['auth']?.toString();
    if (auth == null || auth.isEmpty) {
      throw const FormatException(
        'Broadcasting auth endpoint returned empty "auth" key',
      );
    }

    return PrivateChannelAuthorizationData(authKey: auth);
  }

  static PresenceChannelAuthorizationData _parsePresenceAuthResponse(
    http.Response response,
  ) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const FormatException(
        'Invalid JSON returned by broadcasting auth endpoint',
      );
    }

    Map<dynamic, dynamic>? payload;
    if (decoded is Map) {
      if (decoded.containsKey('auth')) {
        payload = decoded;
      } else if (decoded['data'] is Map &&
          (decoded['data'] as Map).containsKey('auth')) {
        payload = decoded['data'] as Map;
      }
    }

    if (payload == null) {
      throw FormatException(
        'Broadcasting auth endpoint returned payload without "auth" key: '
        '${response.body}',
      );
    }

    final auth = payload['auth']?.toString();
    final rawChannelData = payload['channel_data'];

    if (auth == null || auth.isEmpty) {
      throw const FormatException(
        'Broadcasting auth endpoint returned empty "auth" key',
      );
    }

    String? channelDataEncoded;
    if (rawChannelData is String) {
      channelDataEncoded = rawChannelData;
    } else if (rawChannelData != null) {
      channelDataEncoded = jsonEncode(rawChannelData);
    }

    return PresenceChannelAuthorizationData(
      authKey: auth,
      channelDataEncoded: channelDataEncoded ?? '{}',
    );
  }
}

/// Deprecated spelling of [HostedayRealtimeClient].
@Deprecated('Use HostedayRealtimeClient instead.')
typedef HosteDayRealtimeClient = HostedayRealtimeClient;

/// Legacy callback spelling.
@Deprecated('Use HostedayRealtimeCallback instead.')
typedef HosteDayRealtimeCallback = HostedayRealtimeCallback;
