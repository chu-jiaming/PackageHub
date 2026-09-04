import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/design_system/components/ph_button.dart';

Widget _button({
  PHButtonVariant variant = PHButtonVariant.primary,
  VoidCallback? onPressed,
  bool isLoading = false,
}) {
  return CupertinoApp(
    home: Center(
      child: PHButton(
        label: '继续',
        variant: variant,
        onPressed: onPressed,
        isLoading: isLoading,
      ),
    ),
  );
}

void main() {
  testWidgets('all variants render their label', (tester) async {
    for (final variant in PHButtonVariant.values) {
      await tester.pumpWidget(_button(variant: variant, onPressed: () {}));
      expect(find.text('继续'), findsOneWidget);
    }
  });

  testWidgets('button emits callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_button(onPressed: () => tapped = true));

    await tester.tap(find.text('继续'));
    expect(tapped, isTrue);
  });

  testWidgets('disabled button does not emit callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_button(onPressed: () => tapped = true));

    await tester.pumpWidget(_button(onPressed: null));
    await tester.tap(find.text('继续'));
    expect(tapped, isFalse);
  });

  testWidgets('loading button shows activity indicator and does not emit', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      _button(onPressed: () => tapped = true, isLoading: true),
    );

    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    expect(find.text('继续'), findsNothing);
    await tester.tap(find.byType(CupertinoButton));
    expect(tapped, isFalse);
  });
}
