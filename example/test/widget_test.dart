import 'package:flutter_test/flutter_test.dart';
import 'package:hosteday_flutter_example/app.dart';

void main() {
  testWidgets('Hosteday example app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HostedayExampleApp());

    // Verify that the app shell and guide load without crashing.
    expect(find.byType(HostedayExampleApp), findsOneWidget);
  });
}
