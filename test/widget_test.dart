
import 'package:flutter_test/flutter_test.dart';

import 'package:mobilityone_test/main.dart';

void main() {
  testWidgets('App loads with correct title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OnePayReportApp());

    // Verify that the AppBar title is shown.
    expect(find.text('OnePay Report - Demo'), findsOneWidget);
  });
}