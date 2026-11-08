import 'package:flutter/foundation.dart';

/// Represents an active participant in the Live Bidding Radar.
@immutable
class BidderModel {
  /// Unique identifier of the bidder.
  final String id;

  /// Display name of the bidder.
  final String name;

  /// Optional avatar URL or picture.
  final String? avatarUrl;

  /// Timestamp when the bidder joined the presence channel.
  final DateTime joinedAt;

  const BidderModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.joinedAt,
  });

  /// Constructs a [BidderModel] from a generic JSON map.
  factory BidderModel.fromJson(Map<String, dynamic> json) {
    return BidderModel(
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? '',
      name: json['name']?.toString() ??
          json['user_name']?.toString() ??
          'مزايد نشط',
      avatarUrl: json['avatar_url']?.toString() ?? json['avatar']?.toString(),
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Parses presence event member payloads from Pusher / Reverb.
  factory BidderModel.fromPresenceMap(dynamic data) {
    if (data is Map) {
      final id = data['id']?.toString() ??
          data['user_id']?.toString() ??
          data['userId']?.toString() ??
          '';

      final dynamic rawInfo = data['info'] ?? data['user_info'] ?? data;
      final info = rawInfo is Map ? rawInfo : <String, dynamic>{};

      final name = info['name']?.toString() ??
          info['user_name']?.toString() ??
          (id.isNotEmpty
              ? 'مزايد #${id.length > 4 ? id.substring(id.length - 4) : id}'
              : 'مزايد نشط');

      final avatar =
          info['avatar']?.toString() ?? info['avatar_url']?.toString();

      return BidderModel(
        id: id.isNotEmpty
            ? id
            : 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        avatarUrl: avatar,
        joinedAt: DateTime.now(),
      );
    }

    return BidderModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: 'مزايد متصل',
      avatarUrl: null,
      joinedAt: DateTime.now(),
    );
  }

  /// Parses a presence member when the identifier is provided as a map key (e.g., Pusher presence hash).
  factory BidderModel.fromPresenceMember(String memberId, dynamic memberData) {
    if (memberData is Map) {
      final map = Map<String, dynamic>.from(memberData);
      map['id'] ??= memberId;
      return BidderModel.fromPresenceMap(map);
    }
    final cleanId = memberId.trim();
    return BidderModel(
      id: cleanId,
      name: cleanId.isNotEmpty
          ? 'مزايد #${cleanId.length > 4 ? cleanId.substring(cleanId.length - 4) : cleanId}'
          : 'مزايد نشط',
      avatarUrl: null,
      joinedAt: DateTime.now(),
    );
  }

  /// Serializes the model to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BidderModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

