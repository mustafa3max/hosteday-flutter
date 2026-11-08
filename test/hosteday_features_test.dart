import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

void main() {
  group('HostedayFeatures', () {
    test('default features are enabled', () {
      const features = HostedayFeatures();
      expect(features.isNotificationsEnabled, isTrue);
      expect(features.isRealtimeEnabled, isTrue);
      expect(features.isDatabaseEnabled, isTrue);
      expect(features.isEnabled('custom_flag'), isTrue);
      expect(features.isEnabled('custom_flag', defaultValue: false), isFalse);
    });

    test('parses custom flags correctly from Map', () {
      final features = HostedayFeatures.fromMap({
        'push_notifications': false,
        'realtime_websockets': true,
        'database_management': '0',
        'extra_feature': 'true',
      });

      expect(features.isNotificationsEnabled, isFalse);
      expect(features.isRealtimeEnabled, isTrue);
      expect(features.isDatabaseEnabled, isFalse);
      expect(features.isEnabled('extra_feature'), isTrue);
    });

    test('initializes Hosteday with custom features map', () async {
      await Hosteday.dispose();

      await Hosteday.initializeApp(
        options: const {
          'project_domain': 'test.hosteday.com',
          'features': {
            'push_notifications': false,
            'realtime_websockets': true,
          },
        },
      );

      expect(Hosteday.features.isNotificationsEnabled, isFalse);
      expect(Hosteday.features.isRealtimeEnabled, isTrue);

      await Hosteday.dispose();
    });
  });

  group('FeaturePaywallPage Widget', () {
    testWidgets('renders paywall components correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FeaturePaywallPage.notifications(),
        ),
      );

      expect(find.textContaining('ميزة الإشعارات الفورية غير مفعلة'), findsOneWidget);
      expect(find.textContaining('Upgrade Plan'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
    });
  });
}
