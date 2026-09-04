import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/design_system/components/ph_badge.dart';

void main() {
  testWidgets('all badge variants render their text', (tester) async {
    for (final variant in PHBadgeVariant.values) {
      await tester.pumpWidget(
        CupertinoApp(
          home: PHBadge(label: 'Pro', variant: variant),
        ),
      );
      expect(find.text('Pro'), findsOneWidget);
    }
  });

  testWidgets('badge exposes its label', (tester) async {
    await tester.pumpWidget(
      const CupertinoApp(home: PHBadge(label: 'Completed')),
    );

    expect(find.text('Completed'), findsOneWidget);
    expect(tester.getSize(find.byType(PHBadge)).height, greaterThan(0));
  });
}
