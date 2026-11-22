import 'package:flutter_test/flutter_test.dart';
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

    test('BidEventModel parses whisper json correctly', () {
      final json = <String, dynamic>{
        'bidder_id': 'user_45',
        'bidder_name': 'فهد الدوسري',
        'amount': 2500,
        'timestamp': '2026-11-08T14:30:00.000Z',
      };

      final bid = BidEventModel.fromJson(json);

      expect(bid.bidderId, 'user_45');
      expect(bid.bidderName, 'فهد الدوسري');
      expect(bid.amount, 2500);
      expect(bid.toJson()['amount'], 2500);
      expect(bid.toJson()['bidder_name'], 'فهد الدوسري');
    });
  });
}
