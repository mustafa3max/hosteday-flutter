import 'dart:convert';

/// Represents a realtime event received through HosteDay channels.
///
/// The event contains:
/// - [name]: the received event name.
/// - [channelName]: the channel that delivered the event.
/// - [payload]: normalized event data.
/// - [raw]: the original unprocessed event object.
class HosteDayRealtimeEvent {
  /// The name that identifies the received realtime event.
  ///
  /// Example:
  /// `OrderCreated`
  final String name;

  /// The name of the channel from which the event was received.
  ///
  /// Example:
  /// `private-tenant.orders.1`
  final String channelName;

  /// The normalized event data as a key-value map.
  ///
  /// When the original payload is not a map, it is wrapped inside a map using
  /// either `data` or `message`.
  final Map<String, dynamic> payload;

  /// The original unprocessed event object, when available.
  ///
  /// This is useful when the underlying realtime package exposes extra fields
  /// that are not normalized by this class.
  final Object? raw;

  /// Creates a realtime event with the supplied metadata and payload.
  const HosteDayRealtimeEvent({
    required this.name,
    required this.channelName,
    required this.payload,
    this.raw,
  });

  /// Creates a [HosteDayRealtimeEvent] from raw event data.
  ///
  /// The [data] value is normalized into [payload].
  factory HosteDayRealtimeEvent.fromRaw({
    required String name,
    required String channelName,
    required Object? data,
    Object? raw,
  }) {
    return HosteDayRealtimeEvent(
      name: name,
      channelName: channelName,
      payload: _normalizePayload(data),
      raw: raw,
    );
  }

  /// Alias for [payload].
  ///
  /// This is provided because many realtime APIs refer to event payloads as
  /// `data`.
  Map<String, dynamic> get data => payload;

  /// Reads a payload value by [key].
  ///
  /// Example:
  /// ```dart
  /// final orderId = event['order_id'];
  /// ```
  dynamic operator [](String key) {
    return payload[key];
  }

  /// Whether the payload contains [key].
  bool containsKey(String key) {
    return payload.containsKey(key);
  }

  /// The event message extracted from [payload], when present.
  String? get message => _stringValue('message');

  /// Common identifier extracted from [payload], when present.
  String? get id => _stringValue('id');

  /// Common title extracted from [payload], when present.
  String? get title => _stringValue('title');

  /// Common type extracted from [payload], when present.
  String? get type => _stringValue('type');

  /// The event user data extracted from [payload], when present and valid.
  Map<String, dynamic>? get user {
    final value = payload['user'];

    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  /// The identifier of the user associated with this event, when available.
  String? get userId => user?['id']?.toString();

  /// The display name of the user associated with this event, when available.
  String? get userName => user?['name']?.toString();

  /// The email address of the user associated with this event, when available.
  String? get userEmail => user?['email']?.toString();

  /// Converts this event to a JSON-safe map.
  ///
  /// The [raw] value is intentionally not included because it may contain
  /// objects that cannot be JSON-encoded.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'channel': channelName,
      'payload': payload,
    };
  }

  @override
  String toString() {
    return 'HosteDayRealtimeEvent('
        'name: $name, '
        'channelName: $channelName, '
        'payload: $payload'
        ')';
  }

  String? _stringValue(String key) {
    final value = payload[key];

    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  static Map<String, dynamic> _normalizePayload(Object? data) {
    if (data == null) {
      return <String, dynamic>{};
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    if (data is String) {
      return _normalizeStringPayload(data);
    }

    return <String, dynamic>{
      'data': data,
    };
  }

  static Map<String, dynamic> _normalizeStringPayload(String data) {
    final text = data.trim();

    if (text.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(text);

      if (decoded == null) {
        return <String, dynamic>{};
      }

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return <String, dynamic>{
        'data': decoded,
      };
    } on FormatException {
      return <String, dynamic>{
        'message': data,
      };
    }
  }
}
