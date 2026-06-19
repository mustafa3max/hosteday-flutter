import 'dart:convert';

class HosteDayRealtimeEvent {
  final String name;
  final String channelName;
  final Map<String, dynamic> payload;
  final dynamic raw;

  const HosteDayRealtimeEvent({
    required this.name,
    required this.channelName,
    required this.payload,
    this.raw,
  });

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

  String? get message => payload['message']?.toString();

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

  String? get userId => user?['id']?.toString();

  String? get userName => user?['name']?.toString();

  String? get userEmail => user?['email']?.toString();
}
