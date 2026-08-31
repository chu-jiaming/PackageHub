import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/core/duplicate/pickup_duplicate_detector.dart';
import 'package:packagehub/features/import/duplicate_review_page.dart';
import 'package:packagehub/models/pickup_credential.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

void main() {
  testWidgets('shows duplicate review title and reason', (tester) async {
    final duplicate = _draft(pickupCode: 'DUP');
    final result = _existingResult([_draft(pickupCode: 'UNIQUE'), duplicate]);

    await _pumpHost(tester, result);
    await _openReview(tester);

    expect(find.text('发现重复取件凭证'), findsOneWidget);
    expect(find.text('1 个可能已经存在'), findsOneWidget);
    expect(find.text('已存在于 PackageHub'), findsOneWidget);
    expect(find.text('DUP'), findsOneWidget);
  });

  testWidgets('defaults duplicate item to skip', (tester) async {
    final unique = _draft(pickupCode: 'UNIQUE');
    final duplicate = _draft(pickupCode: 'DUP');
    final result = _existingResult([unique, duplicate]);
    List<PickupCredentialDraft>? returnedDrafts;

    await _pumpHost(
      tester,
      result,
      onResult: (drafts) {
        returnedDrafts = drafts;
      },
    );
    await _openReview(tester);
    await tester.tap(find.byKey(const Key('continueDuplicateReviewButton')));
    await tester.pumpAndSettle();

    expect(returnedDrafts, [unique]);
  });

  testWidgets('choosing keep returns duplicate item', (tester) async {
    final unique = _draft(pickupCode: 'UNIQUE');
    final duplicate = _draft(pickupCode: 'DUP');
    final result = _existingResult([unique, duplicate]);
    List<PickupCredentialDraft>? returnedDrafts;

    await _pumpHost(
      tester,
      result,
      onResult: (drafts) {
        returnedDrafts = drafts;
      },
    );
    await _openReview(tester);
    await tester.tap(_decisionText(1, '仍然保留'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continueDuplicateReviewButton')));
    await tester.pumpAndSettle();

    expect(returnedDrafts, [unique, duplicate]);
  });

  testWidgets('multiple conflicts can be decided separately', (tester) async {
    final unique = _draft(pickupCode: 'UNIQUE', trackingNumber: 'JT000');
    final duplicateA = _draft(pickupCode: 'DUP-A', trackingNumber: 'JT111');
    final duplicateB = _draft(pickupCode: 'DUP-B', trackingNumber: 'JT222');
    final result = DuplicateCheckResult(
      originalDrafts: [unique, duplicateA, duplicateB],
      duplicates: [
        DuplicateCredentialMatch.existing(
          incomingIndex: 1,
          incoming: duplicateA,
          existingCredential: _credential(trackingNumber: 'JT111'),
        ),
        DuplicateCredentialMatch.withinBatch(
          incomingIndex: 2,
          incoming: duplicateB,
          otherIncomingIndex: 0,
          otherIncoming: unique,
        ),
      ],
    );
    List<PickupCredentialDraft>? returnedDrafts;

    await _pumpHost(
      tester,
      result,
      onResult: (drafts) {
        returnedDrafts = drafts;
      },
    );
    await _openReview(tester);
    await tester.tap(_decisionText(2, '仍然保留'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continueDuplicateReviewButton')));
    await tester.pumpAndSettle();

    expect(returnedDrafts, [unique, duplicateB]);
  });

  testWidgets('user back returns null', (tester) async {
    final result = _existingResult([_draft(), _draft(pickupCode: 'DUP')]);
    Object? returnedValue = 'not-set';

    await _pumpHost(
      tester,
      result,
      onResult: (drafts) {
        returnedValue = drafts;
      },
    );
    await _openReview(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(returnedValue, isNull);
  });
}

Finder _decisionText(int incomingIndex, String text) {
  return find.descendant(
    of: find.byKey(Key('duplicateDecision_$incomingIndex')),
    matching: find.text(text),
  );
}

Future<void> _pumpHost(
  WidgetTester tester,
  DuplicateCheckResult result, {
  ValueChanged<List<PickupCredentialDraft>?>? onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: _DuplicateReviewHost(result: result, onResult: onResult),
    ),
  );
}

Future<void> _openReview(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('openDuplicateReviewButton')));
  await tester.pumpAndSettle();
}

DuplicateCheckResult _existingResult(List<PickupCredentialDraft> drafts) {
  return DuplicateCheckResult(
    originalDrafts: drafts,
    duplicates: [
      DuplicateCredentialMatch.existing(
        incomingIndex: 1,
        incoming: drafts[1],
        existingCredential: _credential(),
      ),
    ],
  );
}

PickupCredentialDraft _draft({
  CourierCompany courierCompany = CourierCompany.jtexpress,
  String? trackingNumber = 'JT5519167631350',
  String? pickupCode = 'Z5-2-1350',
}) {
  return PickupCredentialDraft(
    courierCompany: courierCompany,
    trackingNumber: trackingNumber,
    pickupCode: pickupCode,
    stationName: '菜鸟驿站',
    status: PickupStatus.pending,
    sourcePlatform: PackagePlatform.pinduoduo,
    rawText: 'raw OCR text',
  );
}

PickupCredential _credential({String? trackingNumber = 'JT5519167631350'}) {
  final now = DateTime(2026);
  return PickupCredential(
    id: 1,
    courierCompany: CourierCompany.jtexpress,
    trackingNumber: trackingNumber,
    pickupCode: 'Z5-2-1350',
    status: PickupStatus.pending,
    sourcePlatform: PackagePlatform.pinduoduo,
    createdAt: now,
    updatedAt: now,
  );
}

class _DuplicateReviewHost extends StatelessWidget {
  final DuplicateCheckResult result;
  final ValueChanged<List<PickupCredentialDraft>?>? onResult;

  const _DuplicateReviewHost({required this.result, this.onResult});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: const Key('openDuplicateReviewButton'),
          onPressed: () async {
            final drafts = await Navigator.of(context)
                .push<List<PickupCredentialDraft>>(
                  MaterialPageRoute(
                    builder: (context) => DuplicateReviewPage(result: result),
                  ),
                );
            onResult?.call(drafts);
          },
          child: const Text('Open'),
        ),
      ),
    );
  }
}
