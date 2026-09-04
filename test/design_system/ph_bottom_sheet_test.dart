import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/design_system/components/ph_bottom_sheet.dart';
import 'package:packagehub/design_system/components/ph_button.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_radius.dart';

void main() {
  testWidgets('content sizing hugs a short sheet instead of filling viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PHBottomSheet(
            title: '批量管理属于 PackageHub Pro',
            actions: [
              const PHButton(label: '了解 PackageHub Pro', onPressed: null),
              const PHButton(
                label: '取消',
                variant: PHButtonVariant.tertiary,
                onPressed: null,
              ),
            ],
            child: const Text('升级 Pro 后可使用更多能力。'),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(PHBottomSheet)).height, lessThan(420));
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(PHBottomSheet),
        matching: find.byType(Material),
      ),
    );
    expect(
      material.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(PHRadius.xl)),
    );
    expect(
      find.descendant(
        of: find.byType(PHBottomSheet),
        matching: find.byType(Flexible),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(PHBottomSheet),
        matching: find.byType(Expanded),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(PHBottomSheet),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
  });

  testWidgets('uses the semantic dark surface color', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [PHColorScheme.dark]),
        home: Scaffold(body: PHBottomSheet(child: const Text('内容'))),
      ),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(PHBottomSheet),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, PHColorScheme.dark.bgSurface);
  });

  testWidgets('SafeArea contributes only the supplied bottom inset', (
    tester,
  ) async {
    Future<double> pumpWithInset(double bottomInset) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(padding: EdgeInsets.only(bottom: bottomInset)),
            child: Scaffold(
              body: SafeArea(
                bottom: true,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: PHBottomSheet(child: const Text('内容')),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final viewport = tester.getSize(find.byType(MaterialApp));
      return viewport.height -
          tester.getRect(find.byType(PHBottomSheet)).bottom;
    }

    final noInsetBottomGap = await pumpWithInset(0);
    final insetBottomGap = await pumpWithInset(34);
    expect(insetBottomGap - noInsetBottomGap, closeTo(34, 0.01));
  });
}
