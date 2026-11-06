import 'package:flutter_test/flutter_test.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';
import 'package:hosteday_flutter_example/app.dart';

void main() {
  testWidgets('explorer displays configured URLs without sending requests', (
    tester,
  ) async {
    await Hosteday.initializeApp(
      options: {'project_domain': 'example.hosteday.com'},
    );
    addTearDown(Hosteday.dispose);
    await tester.pumpWidget(const HostedayExampleApp());
    expect(find.text('Hosteday API explorer'), findsOneWidget);
    expect(find.textContaining('https://example.hosteday.com/api'), findsOneWidget);
    expect(find.text('Send GET'), findsOneWidget);
  });
}
