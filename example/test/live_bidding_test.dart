import 'package:flutter_test/flutter_test.dart';
import 'package:hosteday_flutter_example/features/live_bidding/models/auction_model.dart';
import 'package:hosteday_flutter_example/features/live_bidding/models/bid_event_model.dart';
import 'package:hosteday_flutter_example/features/live_bidding/models/bidder_model.dart';

void main() {
  group('Live Bidding Models Test', () {
    test('BidderModel parses json correctly', () {
      final json = <String, dynamic>{
        'id': 'user_99',
        'name': 'خالد المنصوري',
        'avatar_url': 'https://example.com/avatar.jpg',
        'joined_at': '2026-11-08T12:00:00.000Z',
      };

      final bidder = BidderModel.fromJson(json);

      expect(bidder.id, 'user_99');
      expect(bidder.name, 'خالد المنصوري');
      expect(bidder.avatarUrl, 'https://example.com/avatar.jpg');
      expect(bidder.joinedAt.isUtc, isTrue);
      expect(bidder.toJson()['id'], 'user_99');
    });

    test('BidderModel parses presence map data with nested info', () {
      final presenceData = <String, dynamic>{
        'id': 'user_101',
        'info': <String, dynamic>{
          'name': 'سارة أحمد',
          'avatar': 'https://example.com/sara.png',
        },
      };

      final bidder = BidderModel.fromPresenceMap(presenceData);

      expect(bidder.id, 'user_101');
      expect(bidder.name, 'سارة أحمد');
      expect(bidder.avatarUrl, 'https://example.com/sara.png');
    });

    test('BidEventModel parses and serializes unified cross-platform payload', () {
      final json = <String, dynamic>{
        'bidder_id': 'user_45',
        'bidder_name': 'فهد الدوسري',
        'amount': 2500,
        'increment': 50,
        'platform': 'android',
        'timestamp': '2026-11-08T14:30:00.000Z',
      };

      final bid = BidEventModel.fromJson(json);

      expect(bid.bidderId, 'user_45');
      expect(bid.bidderName, 'فهد الدوسري');
      expect(bid.amount, 2500);
      expect(bid.increment, 50);
      expect(bid.platform, 'android');
      expect(bid.platformLabel, 'Android');
      expect(bid.timestamp.isUtc, isTrue);

      final encoded = bid.toJson();
      expect(encoded['bidder_id'], 'user_45');
      expect(encoded['bidder_name'], 'فهد الدوسري');
      expect(encoded['amount'], 2500);
      expect(encoded['increment'], 50);
      expect(encoded['platform'], 'android');
      expect(encoded['timestamp'], '2026-11-08T14:30:00.000Z');
    });

    test('AuctionModel parses active row, calculates remaining countdown, and rotates next auction', () {
      final auction1 = AuctionModel.fromJson(<String, dynamic>{
        'id': 1,
        'room_id': 'auction.room',
        'title': 'Rolex Submariner',
        'status': 'active',
        'starting_price': 1000,
        'current_price': 1250,
        'duration_seconds': 300,
        'winner_id': 'u1',
        'winner_name': 'Ali',
        'ends_at': '2026-11-27T12:05:00.000Z',
      });
      final auction2 = AuctionModel.fromJson(<String, dynamic>{
        'id': 2,
        'room_id': 'auction.room',
        'title': 'MacBook Pro M4',
        'status': 'pending',
        'starting_price': 2000,
        'current_price': 2000,
        'duration_seconds': 600,
      });

      expect(auction1.id, 1);
      expect(auction1.title, 'Rolex Submariner');
      expect(auction1.currentPrice, 1250);
      expect(
        auction1.remainingSecondsFrom(DateTime.utc(2026, 11, 27, 12, 0, 0)),
        300,
      );
      expect(
        auction1.remainingSecondsFrom(DateTime.utc(2026, 11, 27, 12, 10, 0)),
        0,
      );

      // Rotation: 1 -> 2, and 2 wraps back to 1
      expect(
        AuctionModel.selectNextAuction([auction2, auction1], 1)?.id,
        2,
      );
      expect(
        AuctionModel.selectNextAuction([auction2, auction1], 2)?.id,
        1,
      );
    });

    test('BidEventModel safely parses decimal string amounts like "1200.00" and computes max amount', () {
      final bids = <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 10,
          'bidder_id': 'u1',
          'bidder_name': 'Mustafa',
          'amount': '1050.00',
          'increment': '50.00',
          'platform': 'android',
          'created_at': '2026-11-27T12:01:00.000Z',
        },
        <String, dynamic>{
          'id': 12,
          'bidder_id': 'u2',
          'bidder_name': 'Ali',
          'amount': '1200.00',
          'increment': '100.00',
          'platform': 'flutter',
          'created_at': '2026-11-27T12:02:00.000Z',
        },
      ].map(BidEventModel.fromJson).toList()
        ..sort((a, b) {
          final cmp = b.exactAmount.compareTo(a.exactAmount);
          return cmp != 0 ? cmp : b.id.compareTo(a.id);
        });

      expect(bids.first.id, 12);
      expect(bids.first.amount, 1200);
      expect(bids.first.exactAmount, 1200.0);
      expect(bids.first.increment, 100);
      expect(bids.last.amount, 1050);
    });
  });
}
