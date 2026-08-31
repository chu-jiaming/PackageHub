import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/features/import/pickup_review_page.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

void main() {
  const initialDraft = PickupCredentialDraft(
    courierCompany: CourierCompany.jtexpress,
    trackingNumber: 'JT5519167631350',
    pickupCode: 'Z5-2-1350',
    stationName: '某快递服务中心',
    status: PickupStatus.pending,
    sourcePlatform: PackagePlatform.pinduoduo,
    rawText: '拼多多\n取件码 Z5-2-1350\n某快递服务中心',
  );

  testWidgets('shows parser initial values', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PickupReviewPage(originalDraft: initialDraft)),
    );

    expect(find.text('确认取件信息'), findsWidgets);
    expect(find.text('自动识别结果可能有误，请核对后继续。'), findsOneWidget);
    expect(find.text('极兔速递'), findsOneWidget);
    expect(find.text('Z5-2-1350'), findsOneWidget);
    expect(find.text('某快递服务中心'), findsNothing);
    expect(find.byKey(const Key('stationNameField')), findsNothing);
    expect(find.text('取件点'), findsNothing);
    expect(find.text('JT5519167631350'), findsOneWidget);
    expect(find.text('待取件'), findsOneWidget);
    expect(find.text('识别来源：拼多多'), findsOneWidget);
  });

  testWidgets('returns edited pickup code on confirm', (tester) async {
    PickupCredentialDraft? result;

    await _pumpRouteHost(
      tester,
      draft: initialDraft,
      onResult: (draft) => result = draft,
    );
    await _openReviewPage(tester);

    await tester.enterText(
      find.byKey(const Key('pickupCodeField')),
      'A3-1-2048',
    );
    await _tapConfirm(tester);

    expect(result?.pickupCode, 'A3-1-2048');
    expect(result?.stationName, '某快递服务中心');
  });

  testWidgets('returns edited courier without changing source platform', (
    tester,
  ) async {
    PickupCredentialDraft? result;

    await _pumpRouteHost(
      tester,
      draft: initialDraft,
      onResult: (draft) => result = draft,
    );
    await _openReviewPage(tester);

    await tester.tap(find.byKey(const Key('courierCompanyField')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).last, const Offset(0, 260));
    await tester.pumpAndSettle();
    await tester.tap(find.text('顺丰速运').last);
    await tester.pumpAndSettle();
    await _tapConfirm(tester);

    expect(result?.courierCompany, CourierCompany.sfExpress);
    expect(result?.sourcePlatform, PackagePlatform.pinduoduo);
    expect(result?.stationName, '某快递服务中心');
  });

  testWidgets('keeps station name when confirming without station UI', (
    tester,
  ) async {
    PickupCredentialDraft? result;

    await _pumpRouteHost(
      tester,
      draft: initialDraft,
      onResult: (draft) => result = draft,
    );
    await _openReviewPage(tester);

    await _tapConfirm(tester);

    expect(result?.stationName, '某快递服务中心');
  });

  testWidgets('system back returns null without throwing', (tester) async {
    PickupCredentialDraft? result = initialDraft;
    var completed = false;

    await _pumpRouteHost(
      tester,
      draft: initialDraft,
      onResult: (draft) {
        result = draft;
        completed = true;
      },
    );
    await _openReviewPage(tester);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, isNull);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpRouteHost(
  WidgetTester tester, {
  required PickupCredentialDraft draft,
  required ValueChanged<PickupCredentialDraft?> onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: FilledButton(
                key: const Key('openReviewButton'),
                onPressed: () async {
                  final result = await Navigator.of(context)
                      .push<PickupCredentialDraft>(
                        MaterialPageRoute(
                          builder: (context) =>
                              PickupReviewPage(originalDraft: draft),
                        ),
                      );

                  onResult(result);
                },
                child: const Text('打开确认页'),
              ),
            ),
          );
        },
      ),
    ),
  );
}

Future<void> _openReviewPage(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('openReviewButton')));
  await tester.pumpAndSettle();
}

Future<void> _tapConfirm(WidgetTester tester) async {
  final confirmButton = find.byKey(const Key('confirmPickupButton'));
  await tester.ensureVisible(confirmButton);
  await tester.pumpAndSettle();
  await tester.tap(confirmButton);
  await tester.pumpAndSettle();
}
