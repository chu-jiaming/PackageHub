import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/design_system/components/ph_bottom_sheet.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
import 'package:packagehub/subscription/mock_subscription_repository.dart';
import 'package:packagehub/subscription/pro_upgrade_sheet.dart';

void main() {
  testWidgets('Pro upgrade sheet hugs content and keeps actions accessible', (
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
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showProUpgradeSheet(
                context,
                subscriptionRepository: const MockSubscriptionRepository(),
                title: '批量管理属于 PackageHub Pro',
                body: '升级 Pro 后可批量标记已取件和批量删除。',
                secondaryLabel: '取消',
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.text('批量管理属于 PackageHub Pro'), findsOneWidget);
    expect(find.byKey(const Key('proUpsellPrimaryButton')), findsOneWidget);
    expect(find.byKey(const Key('proUpsellSecondaryButton')), findsOneWidget);

    final sheet = tester.getRect(find.byType(PHBottomSheet));
    final secondary = tester.getRect(
      find.byKey(const Key('proUpsellSecondaryButton')),
    );
    expect(sheet.height, lessThan(420));
    final bottomGap = sheet.bottom - secondary.bottom;
    expect(bottomGap, closeTo(PHSpacing.lg, 0.01));
    expect(bottomGap, lessThan(80));

    await tester.tap(find.byKey(const Key('proUpsellSecondaryButton')));
    await tester.pumpAndSettle();
    expect(find.byType(PHBottomSheet), findsNothing);
  });
}
