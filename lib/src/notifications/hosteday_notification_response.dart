import 'dart:collection';

/// Represents the response returned when interacting with the HosteDay notification service.
///
/// Implements [Map] via [MapMixin] for seamless backward compatibility
/// with callers expecting raw [Map<String, dynamic>].
class HosteDayNotificationResponse with MapMixin<String, dynamic> {
  final Map<String, dynamic> _raw;

  /// Whether the notification operation succeeded.
  final bool success;

  /// The unique message identifier returned by the server or gateway.
  final String? messageId;

  /// Error message when [success] is false.
  final String? error;

  /// Additional payload data returned by the server.
  final Map<String, dynamic>? data;

  HosteDayNotificationResponse({
    required this.success,
    this.messageId,
    this.error,
    this.data,
    Map<String, dynamic>? raw,
  }) : _raw = raw != null
            ? Map<String, dynamic>.unmodifiable(raw)
            : Map<String, dynamic>.unmodifiable(<String, dynamic>{
                'success': success,
                if (messageId != null) 'message_id': messageId,
                if (error != null) 'error': error,
                if (data != null) 'data': data,
              });

  /// Creates a [HosteDayNotificationResponse] from JSON.
  factory HosteDayNotificationResponse.fromJson(Map<String, dynamic> json) {
    final success = json['success'] == true;

    final rawData = json['data'];
    final dataMap = rawData is Map<String, dynamic>
        ? rawData
        : (rawData is Map ? Map<String, dynamic>.from(rawData) : null);

    final rawMessageId = json['message_id'] ??
        json['messageId'] ??
        dataMap?['message_id'] ??
        dataMap?['messageId'];

    final rawError = json['error'] ??
        (!success
            ? (json['message'] ?? 'Notification dispatch failed.')
            : null);

    return HosteDayNotificationResponse(
      success: success,
      messageId: rawMessageId?.toString(),
      error: rawError?.toString(),
      data: dataMap,
      raw: json,
    );
  }

  // ---------------------------------------------------------------------------
  // MapMixin implementation for 100% backward compatibility
  // ---------------------------------------------------------------------------

  @override
  dynamic operator [](Object? key) => _raw[key];

  @override
  void operator []=(String key, dynamic value) {
    throw UnsupportedError('HosteDayNotificationResponse is unmodifiable.');
  }

  @override
  void clear() {
    throw UnsupportedError('HosteDayNotificationResponse is unmodifiable.');
  }

  @override
  Iterable<String> get keys => _raw.keys;

  @override
  dynamic remove(Object? key) {
    throw UnsupportedError('HosteDayNotificationResponse is unmodifiable.');
  }

  /// Converts the response to a JSON-compatible map.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(_raw);

  @override
  String toString() {
    return 'HosteDayNotificationResponse('
        'success: $success, '
        'messageId: $messageId, '
        'error: $error, '
        'data: $data'
        ')';
  }
}

/// Preferred spelling of [HosteDayNotificationResponse].
typedef HostedayNotificationResponse = HosteDayNotificationResponse;
