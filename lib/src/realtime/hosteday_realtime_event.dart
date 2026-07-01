import 'dart:convert';

/// Represents a real-time event received through HosteDay channels.
///
/// The event contains its [name], the originating [channelName], a normalized
/// [payload], and the optional unprocessed [raw] data received from the source.
class HosteDayRealtimeEvent {
  /// The name that identifies the received real-time event.
  final String name;

  /// The name of the channel from which the event was received.
  final String channelName;

  /// The normalized event data as a key-value map.
  ///
  /// When the original payload is not a map, it is converted to a map where
  /// possible to provide a consistent structure for consumers.
  final Map<String, dynamic> payload;

  /// The original unprocessed event data, when available.
  final dynamic raw;

  /// Creates a real-time event with the supplied event metadata and payload.
  ///
  /// The [name] identifies the event type, while [channelName] identifies the
  /// channel that delivered it. The [payload] contains the normalized data.
  const HosteDayRealtimeEvent({
    required this.name,
    required this.channelName,
    required this.payload,
    this.raw,
  });

  /// Creates a [HosteDayRealtimeEvent] from raw event data.
  ///
  /// The [data] value is normalized into a map before it is assigned to
  /// [payload]. The optional [raw] value preserves the original event data
  /// for cases where direct access is needed.
  factory HosteDayRealtimeEvent.fromRaw({
    required String name,
    required String channelName,
    required dynamic data,
    dynamic raw,
  }) {
    return HosteDayRealtimeEvent(
      name: name,
      channelName: channelName,
      payload: _normalizePayload(data),
      raw: raw,
    );
  }

  static Map<String, dynamic> _normalizePayload(dynamic data) {
    if (data == null) return <String, dynamic>{};

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    if (data is String) {
      try {
        final decoded = jsonDecode(data);

        if (decoded is Map<String, dynamic>) {
          return decoded;
        }

        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }

        return <String, dynamic>{'data': decoded};
      } catch (_) {
        return <String, dynamic>{'message': data};
      }
    }

    return <String, dynamic>{'data': data};
  }

  /// The event message extracted from [payload], when present.
  ///
  /// Returns `null` when the payload does not include a `message` value.
  String? get message => payload['message']?.toString();

  /// The event user data extracted from [payload], when present and valid.
  ///
  /// Returns `null` when no `user` value exists or when it cannot be converted
  /// to a map.
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
}
