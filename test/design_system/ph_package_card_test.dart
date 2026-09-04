import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/design_system/components/ph_package_card.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';

Widget _app({
  required PHPackageCardState state,
  String? pickupCode = 'A-1-2',
  String? trackingNumber = 'SF123',
  String? location = '南门驿站',
  VoidCallback? onComplete,
}) {
  return MaterialApp(
    home: Scaffold(
      body: PHPackageCard(
        state: state,
        pickupCode: pickupCode,
        trackingNumber: trackingNumber,
        location: location,
        onComplete: onComplete,
      ),
    ),
  );
}

void main() {
  testWidgets('active state renders package data and complete action', (
    tester,
  ) async {
    await tester.pumpWidget(_app(state: PHPackageCardState.active));

    expect(find.text('A-1-2'), findsOneWidget);
    expect(find.text('取件码'), findsOneWidget);
    expect(find.text('SF123'), findsOneWidget);
    expect(find.text('南门驿站'), findsOneWidget);
    expect(
      find.byKey(const Key('phPackageCardCompleteAction')),
      findsOneWidget,
    );

    final code = tester.widget<Text>(find.text('A-1-2'));
    expect(code.style?.fontSize, 28);
    expect(code.style?.height, 34 / 28);
    expect(code.style?.letterSpacing, -0.4);
    final trackingLabel = tester.widget<Text>(find.text('运单号'));
    expect(trackingLabel.style?.color, PHColorScheme.light.textTertiary);
    final trackingValue = tester.widget<Text>(find.text('SF123'));
    expect(trackingValue.style?.color, PHColorScheme.light.textSecondary);
    expect(trackingValue.style?.fontWeight, FontWeight.w600);
    expect(trackingValue.textAlign, TextAlign.end);

    final divider = tester.getRect(find.byType(Divider));
    expect(
      divider.top - tester.getRect(find.text('A-1-2')).bottom,
      greaterThanOrEqualTo(PHSpacing.sm),
    );
    expect(
      tester.getRect(find.text('SF123')).top - divider.bottom,
      greaterThanOrEqualTo(PHSpacing.sm),
    );
  });

  testWidgets('completed state renders completed styling', (tester) async {
    await tester.pumpWidget(_app(state: PHPackageCardState.completed));

    final card = tester.widget<PHPackageCard>(find.byType(PHPackageCard));
    expect(card.state, PHPackageCardState.completed);
    expect(find.text('已取件'), findsOneWidget);
  });

  testWidgets('long pickup code remains fully visible on a narrow card', (
    tester,
  ) async {
    const code = 'JT-2026-09-04-1234567890';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: PHPackageCard(
              state: PHPackageCardState.active,
              pickupCode: code,
              trackingNumber: null,
              location: null,
              onComplete: null,
            ),
          ),
        ),
      ),
    );

    expect(find.text(code), findsOneWidget);
    expect(tester.getSize(find.byType(FittedBox)).width, lessThan(260));
  });

  testWidgets('nullable tracking and location render safely', (tester) async {
    await tester.pumpWidget(
      _app(
        state: PHPackageCardState.active,
        trackingNumber: null,
        location: null,
      ),
    );

    expect(find.text('—'), findsNWidgets(2));
    for (final emptyValue in tester.widgetList<Text>(find.text('—'))) {
      expect(emptyValue.style?.color, PHColorScheme.light.textTertiary);
    }
  });

  testWidgets('complete action has a 44 point hit target and emits callback', (
    tester,
  ) async {
    var completed = false;
    await tester.pumpWidget(
      _app(
        state: PHPackageCardState.active,
        onComplete: () => completed = true,
      ),
    );

    final size = tester.getSize(
      find.byKey(const Key('phPackageCardCompleteAction')),
    );
    expect(size, const Size(44, 44));
    await tester.tap(find.byKey(const Key('phPackageCardCompleteAction')));
    expect(completed, isTrue);
  });

  testWidgets('card uses available width instead of fixed reference width', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            child: PHPackageCard(
              state: PHPackageCardState.active,
              pickupCode: 'WIDE',
              trackingNumber: null,
              location: null,
              onComplete: null,
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(PHPackageCard)), const Size(500, 137));
  });
}
