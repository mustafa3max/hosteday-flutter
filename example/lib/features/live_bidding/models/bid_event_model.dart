import 'package:flutter/foundation.dart';

/// Represents a live bid placed during an active auction session.
@immutable
class BidEventModel {
  /// Unique identifier of the bidder who placed this bid.
  final String bidderId;

  /// Display name of the bidder.
  final String bidderName;

  /// Offer amount in dollars ($).
  final int amount;

  /// Time when the bid occurred.
  final DateTime timestamp;

  const BidEventModel({
    required this.bidderId,
    required this.bidderName,
    required this.amount,
    required this.timestamp,
  });

  /// Constructs a [BidEventModel] from a decoded JSON or Whisper map.
  factory BidEventModel.fromJson(Map<String, dynamic> json) {
    return BidEventModel(
      bidderId: json['bidder_id']?.toString() ??
          json['user_id']?.toString() ??
          'anonymous',
      bidderName: json['bidder_name']?.toString() ??
          json['user_name']?.toString() ??
          'مزايد غير معروف',
      amount: int.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Serializes the bid event to a Whisper / JSON payload.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'bidder_id': bidderId,
      'bidder_name': bidderName,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

