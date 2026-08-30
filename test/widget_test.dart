// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:packagehub/main.dart';

void main() {
  testWidgets('Home page shows import screenshot action', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PackageHubApp());

    expect(find.text('PackageHub'), findsOneWidget);
    expect(find.text('添加截图'), findsOneWidget);
  });
}
