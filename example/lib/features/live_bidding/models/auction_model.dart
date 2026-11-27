import 'package:flutter/foundation.dart';

/// Represents an auction item stored in the `auctions` Hosteday table.
@immutable
class AuctionModel {
  final int id;
  final String roomId;
  final String title;
  final String status;
  final int startingPrice;
  final int currentPrice;
  final int durationSeconds;
  final String? winnerId;
  final String? winnerName;
  final DateTime? endsAt;

  const AuctionModel({
    required this.id,
    required this.roomId,
    required this.title,
    required this.status,
    required this.startingPrice,
    required this.currentPrice,
    required this.durationSeconds,
    this.winnerId,
    this.winnerName,
    this.endsAt,
  });

  factory AuctionModel.fromJson(Map<String, dynamic> json) {
    final id = _parseInt(json['id']) ?? 0;
    final startingPrice = _parseInt(json['starting_price']) ?? 1000;
    final currentPrice = _parseInt(json['current_price']) ?? startingPrice;
    final durationSeconds = _parseInt(json['duration_seconds']) ?? 300;

    return AuctionModel(
      id: id,
      roomId: json['room_id']?.toString().trim().isNotEmpty == true
          ? json['room_id'].toString().trim()
          : 'auction.room',
      title: json['title']?.toString().trim().isNotEmpty == true
          ? json['title'].toString().trim()
          : 'Auction #$id',
      status: json['status']?.toString().trim().isNotEmpty == true
          ? json['status'].toString().trim()
          : 'pending',
      startingPrice: startingPrice,
      currentPrice: currentPrice,
      durationSeconds: durationSeconds > 0 ? durationSeconds : 300,
      winnerId: json['winner_id']?.toString().trim().isNotEmpty == true
          ? json['winner_id'].toString().trim()
          : null,
      winnerName: json['winner_name']?.toString().trim().isNotEmpty == true
          ? json['winner_name'].toString().trim()
          : null,
      endsAt: _parseUtcDate(json['ends_at']),
    );
  }

  /// Calculates remaining countdown seconds directly from [endsAt] in UTC.
  int remainingSecondsFrom(DateTime nowUtc) {
    final end = endsAt;
    if (end == null) {
      return durationSeconds;
    }
    final diff = end.toUtc().difference(nowUtc.toUtc()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// Returns a copy with updated active rotation fields.
  AuctionModel copyWith({
    String? status,
    int? currentPrice,
    String? winnerId,
    String? winnerName,
    bool clearWinner = false,
    DateTime? endsAt,
  }) {
    return AuctionModel(
      id: id,
      roomId: roomId,
      title: title,
      status: status ?? this.status,
      startingPrice: startingPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      durationSeconds: durationSeconds,
      winnerId: clearWinner ? null : (winnerId ?? this.winnerId),
      winnerName: clearWinner ? null : (winnerName ?? this.winnerName),
      endsAt: endsAt ?? this.endsAt,
    );
  }

  /// Selects the next auction in rotation order (`id > currentId`, wrapping to first).
  static AuctionModel? selectNextAuction(
    List<AuctionModel> auctions,
    int currentId,
  ) {
    if (auctions.isEmpty) return null;
    final sorted = List<AuctionModel>.from(auctions)
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final auction in sorted) {
      if (auction.id > currentId) {
        return auction;
      }
    }
    return sorted.first;
  }

  /// Extracts a list of row maps from a Hosteday REST index/envelope response.
  static List<Map<String, dynamic>> extractRows(Map<String, dynamic> response) {
    dynamic raw = response['data'];
    if (raw is Map && raw['data'] is List) {
      raw = raw['data'];
    } else if (raw is Map && raw['items'] is List) {
      raw = raw['items'];
    } else if (raw == null && response['items'] is List) {
      raw = response['items'];
    } else if (raw == null && response['records'] is List) {
      raw = response['records'];
    }

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    final str = value.toString().trim();
    if (str.isEmpty) return null;
    return int.tryParse(str) ?? double.tryParse(str)?.toInt();
  }

  static DateTime? _parseUtcDate(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    // Handle both ISO-8601 (`2026-11-27T09:00:00Z`) and SQL (`2026-11-27 09:00:00`)
    final normalized = raw.contains('T')
        ? raw
        : '${raw.replaceFirst(' ', 'T')}Z';
    return DateTime.tryParse(normalized)?.toUtc();
  }
}
