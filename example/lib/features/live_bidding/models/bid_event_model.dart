import 'package:flutter/foundation.dart';

/// Represents a live bid placed during an active auction session.
@immutable
class BidEventModel {
  /// Optional database record ID from `auction_bids`.
  final int id;

  /// Unique identifier of the bidder who placed this bid.
  final String bidderId;

  /// Display name of the bidder.
  final String bidderName;

  /// Offer amount in dollars ($).
  final int amount;

  /// Exact numeric amount (supports decimal strings like `"1250.00"`).
  final double exactAmount;

  /// Bid increment amount in dollars ($).
  final int increment;

  /// Source platform of the bidder (e.g. `flutter`, `android`).
  final String platform;

  /// Time when the bid occurred (UTC).
  final DateTime timestamp;

  const BidEventModel({
    this.id = 0,
    required this.bidderId,
    required this.bidderName,
    required this.amount,
    double? exactAmount,
    this.increment = 0,
    this.platform = 'flutter',
    required this.timestamp,
  }) : exactAmount = exactAmount ?? amount * 1.0;

  /// Human-readable platform label (`Flutter` or `Android`).
  String get platformLabel {
    switch (platform.trim().toLowerCase()) {
      case 'flutter':
        return 'Flutter';
      case 'android':
      case 'kotlin':
        return 'Android';
      case 'ios':
        return 'iOS';
      case 'web':
        return 'Web';
      default:
        return platform.trim().isEmpty ? 'Unknown' : platform.trim();
    }
  }

  /// Safely parses a numeric value from `int`, `double`, or decimal `String` (e.g. `"1200.00"`).
  static double parseDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim()) ?? fallback;
  }

  /// Constructs a [BidEventModel] from a decoded JSON or Whisper map.
  factory BidEventModel.fromJson(Map<String, dynamic> json) {
    final parsedId = parseDouble(json['id']).round();
    final parsedAmount = parseDouble(json['amount']);
    final parsedIncrement = parseDouble(json['increment']).round();
    final rawTime = json['timestamp'] ?? json['created_at'];

    return BidEventModel(
      id: parsedId,
      bidderId:
          json['bidder_id']?.toString() ??
          json['user_id']?.toString() ??
          'anonymous',
      bidderName:
          json['bidder_name']?.toString() ??
          json['user_name']?.toString() ??
          'مزايد غير معروف',
      amount: parsedAmount.round(),
      exactAmount: parsedAmount,
      increment: parsedIncrement,
      platform: json['platform']?.toString().trim().isNotEmpty == true
          ? json['platform'].toString().trim()
          : 'flutter',
      timestamp: rawTime != null
          ? (DateTime.tryParse(rawTime.toString()) ?? DateTime.now()).toUtc()
          : DateTime.now().toUtc(),
    );
  }

  /// Serializes the bid event to the unified cross-platform Whisper / JSON payload.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'bidder_id': bidderId,
      'bidder_name': bidderName,
      'amount': amount,
      'increment': increment,
      'platform': platform,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }
}
