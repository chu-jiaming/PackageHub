import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/design_system/components/ph_button.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';

Widget _button({
  PHButtonVariant variant = PHButtonVariant.primary,
  VoidCallback? onPressed,
  bool isLoading = false,
  Widget? leading,
}) {
  return CupertinoApp(
    home: Center(
      child: PHButton(
        label: '继续',
        variant: variant,
        onPressed: onPressed,
        isLoading: isLoading,
        leading: leading,
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

  testWidgets('primary button shares its foreground with a leading icon', (
    tester,
  ) async {
    const iconKey = Key('primaryButtonLeadingIcon');
    await tester.pumpWidget(
      _button(
        onPressed: () {},
        leading: const Icon(Icons.add, key: iconKey),
      ),
    );

    final text = tester.widget<Text>(find.text('继续'));
    expect(text.style?.color, PHColorScheme.light.textInverse);

    final iconTheme = tester
        .widgetList<IconTheme>(
          find.ancestor(
            of: find.byKey(iconKey),
            matching: find.byType(IconTheme),
          ),
        )
        .firstWhere((theme) => theme.data.color != null);
    expect(iconTheme.data.color, PHColorScheme.light.textInverse);
  });

  testWidgets('disabled button keeps disabled leading icon color', (
    tester,
  ) async {
    const iconKey = Key('disabledButtonLeadingIcon');
    await tester.pumpWidget(
      _button(leading: const Icon(Icons.add, key: iconKey), onPressed: null),
    );

    final iconTheme = tester
        .widgetList<IconTheme>(
          find.ancestor(
            of: find.byKey(iconKey),
            matching: find.byType(IconTheme),
          ),
        )
        .firstWhere((theme) => theme.data.color != null);
    expect(iconTheme.data.color, PHColorScheme.light.textDisabled);
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
    expect(
      tester
          .widget<CupertinoActivityIndicator>(
            find.byType(CupertinoActivityIndicator),
          )
          .color,
      PHColorScheme.light.textInverse,
    );
    await tester.tap(find.byType(CupertinoButton));
    expect(tapped, isFalse);
  });
}
