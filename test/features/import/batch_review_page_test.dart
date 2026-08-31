import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/features/import/batch_review_page.dart';
import 'package:packagehub/features/import/image_preview_page.dart';
import 'package:packagehub/features/import/pickup_review_item.dart';
import 'package:packagehub/features/import/pickup_review_page.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

void main() {
  testWidgets('shows a single review item', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: BatchReviewPage.withItems(items: [_items.first])),
    );

    expect(find.text('确认取件信息'), findsWidgets);
    expect(find.text('1 个识别结果'), findsOneWidget);
    expect(find.byKey(const Key('batchReviewItem_0')), findsOneWidget);
    expect(find.byKey(const Key('pickupCodeField')), findsOneWidget);
    expect(find.byKey(const Key('confirmAllButton')), findsOneWidget);
  });

  testWidgets('shows three review items', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: BatchReviewPage.withItems(items: _items)),
    );

    expect(find.text('3 个识别结果'), findsOneWidget);
    expect(find.byKey(const Key('batchReviewItem_0')), findsOneWidget);
    expect(find.byKey(const Key('batchReviewItem_1')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('batchReviewItem_2')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('batchReviewItem_2')), findsOneWidget);
    expect(find.text('极兔速递'), findsOneWidget);
    expect(find.text('顺丰速运'), findsOneWidget);
    expect(find.text('未识别快递公司'), findsOneWidget);
  });

  testWidgets('compact review does not show station name or station label', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: BatchReviewPage.withItems(items: _items)),
    );

    expect(find.text('兔喜快递超市'), findsNothing);
    expect(find.text('丰巢智能柜'), findsNothing);
    expect(find.text('取件点'), findsNothing);
  });

  testWidgets('confirm all stays visible after scrolling the review list', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: BatchReviewPage.withItems(items: _items)),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('confirmAllButton')), findsOneWidget);
  });

  testWidgets('multiple review items do not overflow while scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: BatchReviewPage.withItems(items: _items)),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();
    await _tapEdit(tester, 1);

    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the second edit button expands the second editor', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: BatchReviewPage.withItems(items: _items)),
    );

    await _tapEdit(tester, 1);

    expect(find.byKey(const Key('pickupCodeField')), findsOneWidget);
    expect(find.byKey(const Key('trackingNumberField')), findsOneWidget);
    expect(find.byKey(const Key('stationNameField')), findsNothing);
    expect(find.text('取件点'), findsNothing);
    expect(find.text('8-3-2051'), findsOneWidget);
  });

  testWidgets(
    'editing the second pickup code keeps the other drafts unchanged',
    (tester) async {
      List<PickupCredentialDraft>? result;

      await _pumpRouteHost(
        tester,
        items: _items,
        onResult: (drafts) => result = drafts,
      );

      await _openBatchReview(tester);
      await _tapEdit(tester, 1);
      await tester.enterText(
        find.byKey(const Key('pickupCodeField')),
        '9-9-9999',
      );
      await tester.pump();
      await _tapConfirmAll(tester);

      expect(result, hasLength(3));
      expect(result?[0].pickupCode, 'Z5-2-1350');
      expect(result?[1].pickupCode, '9-9-9999');
      expect(result?[2].pickupCode, isNull);
      expect(result?[0].stationName, '兔喜快递超市');
      expect(result?[1].stationName, '丰巢智能柜');
    },
  );

  testWidgets('edited value is kept after completing edit', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: BatchReviewPage.withItems(items: _items)),
    );

    await _tapEdit(tester, 1);
    await tester.enterText(
      find.byKey(const Key('pickupCodeField')),
      '9-9-9999',
    );
    await tester.pump();
    await _tapCompleteEdit(tester);

    expect(find.byKey(const Key('pickupCodeField')), findsNothing);
    expect(find.text('9-9-9999'), findsOneWidget);
  });

  testWidgets('edited value appears when expanding the same item again', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: BatchReviewPage.withItems(items: _items)),
    );

    await _tapEdit(tester, 1);
    await tester.enterText(
      find.byKey(const Key('pickupCodeField')),
      '9-9-9999',
    );
    await tester.pump();
    await _tapCompleteEdit(tester);
    await _tapEdit(tester, 1);

    expect(find.text('9-9-9999'), findsOneWidget);
    expect(find.byKey(const Key('pickupCodeField')), findsOneWidget);
  });

  testWidgets('tapping a screenshot opens the fullscreen image preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: BatchReviewPage.withItems(items: _items)),
    );

    await _tapScreenshot(tester, 0);

    expect(find.byType(ImagePreviewPage), findsOneWidget);
    expect(find.text('查看截图'), findsOneWidget);
  });

  testWidgets('returning from image preview keeps editing state and content', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: BatchReviewPage.withItems(items: _items)),
    );

    await _tapEdit(tester, 1);
    await tester.enterText(
      find.byKey(const Key('pickupCodeField')),
      '9-9-9999',
    );
    await tester.pump();
    await _tapScreenshot(tester, 1);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pickupCodeField')), findsOneWidget);
    expect(find.text('9-9-9999'), findsOneWidget);
  });

  testWidgets('fullscreen image preview uses InteractiveViewer', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ImagePreviewPage(imagePath: 'one.png')),
    );

    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('confirm all returns a list of drafts', (tester) async {
    List<PickupCredentialDraft>? result;

    await _pumpRouteHost(
      tester,
      items: _items,
      onResult: (drafts) => result = drafts,
    );

    await _openBatchReview(tester);
    await _tapConfirmAll(tester);

    expect(result, hasLength(3));
    expect(result?[0].pickupCode, 'Z5-2-1350');
    expect(result?[1].pickupCode, '8-3-2051');
    expect(result?[2].courierCompany, CourierCompany.unknown);
    expect(result?[0].stationName, '兔喜快递超市');
    expect(result?[1].stationName, '丰巢智能柜');
  });

  testWidgets('confirm all returns user edited values', (tester) async {
    List<PickupCredentialDraft>? result;

    await _pumpRouteHost(
      tester,
      items: _items,
      onResult: (drafts) => result = drafts,
    );

    await _openBatchReview(tester);
    await _tapEdit(tester, 1);
    await tester.enterText(
      find.byKey(const Key('pickupCodeField')),
      '9-9-9999',
    );
    await tester.pump();
    await _tapConfirmAll(tester);

    expect(result?[1].pickupCode, '9-9-9999');
    expect(result?[1].stationName, '丰巢智能柜');
  });

  testWidgets('editing does not push the legacy pickup review page', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: BatchReviewPage.withItems(items: _items)),
    );

    await _tapEdit(tester, 1);

    expect(find.byType(PickupReviewPage), findsNothing);
    expect(find.byType(BatchReviewPage), findsOneWidget);
  });
}

Future<void> _pumpRouteHost(
  WidgetTester tester, {
  required List<PickupReviewItem> items,
  required ValueChanged<List<PickupCredentialDraft>?> onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: FilledButton(
              key: const Key('openBatchReviewHostButton'),
              onPressed: () async {
                final result = await Navigator.of(context)
                    .push<List<PickupCredentialDraft>>(
                      MaterialPageRoute(
                        builder: (context) =>
                            BatchReviewPage.withItems(items: items),
                      ),
                    );

                onResult(result);
              },
              child: const Text('打开批量确认'),
            ),
          );
        },
      ),
    ),
  );
}

Future<void> _openBatchReview(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('openBatchReviewHostButton')));
  await tester.pumpAndSettle();
}

Future<void> _tapEdit(WidgetTester tester, int index) async {
  final editButton = find.byKey(Key('editDraftButton_$index'));
  await tester.ensureVisible(editButton);
  await tester.pumpAndSettle();
  await tester.tap(editButton);
  await tester.pumpAndSettle();
}

Future<void> _tapScreenshot(WidgetTester tester, int index) async {
  final screenshot = find.byKey(Key('reviewScreenshot_$index'));
  await tester.ensureVisible(screenshot);
  await tester.pumpAndSettle();
  await tester.tap(screenshot);
  await tester.pumpAndSettle();
}

Future<void> _tapCompleteEdit(WidgetTester tester) async {
  final completeButton = find.byKey(const Key('completeReviewEditButton'));
  await tester.ensureVisible(completeButton);
  await tester.pumpAndSettle();
  await tester.tap(completeButton);
  await tester.pumpAndSettle();
}

Future<void> _tapConfirmAll(WidgetTester tester) async {
  final confirmButton = find.byKey(const Key('confirmAllButton'));
  await tester.tap(confirmButton);
  await tester.pumpAndSettle();
}

const _items = [
  PickupReviewItem(
    imagePath: 'one.png',
    draft: PickupCredentialDraft(
      courierCompany: CourierCompany.jtexpress,
      trackingNumber: 'JT5519167631350',
      pickupCode: 'Z5-2-1350',
      stationName: '兔喜快递超市',
      status: PickupStatus.pending,
      sourcePlatform: PackagePlatform.pinduoduo,
      rawText: '极兔速递\n取件码 Z5-2-1350\n兔喜快递超市',
    ),
  ),
  PickupReviewItem(
    imagePath: 'two.png',
    draft: PickupCredentialDraft(
      courierCompany: CourierCompany.sfExpress,
      trackingNumber: 'SF1234567890',
      pickupCode: '8-3-2051',
      stationName: '丰巢智能柜',
      status: PickupStatus.pending,
      sourcePlatform: PackagePlatform.taobao,
      rawText: '顺丰速运\n取件码 8-3-2051\n丰巢智能柜',
    ),
  ),
  PickupReviewItem(
    imagePath: 'three.png',
    draft: PickupCredentialDraft(
      courierCompany: CourierCompany.unknown,
      trackingNumber: null,
      pickupCode: null,
      stationName: null,
      status: PickupStatus.unknown,
      sourcePlatform: PackagePlatform.unknown,
      rawText: '无法识别',
    ),
  ),
];
