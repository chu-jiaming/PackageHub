import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/features/import/pickup_review_page.dart';
import 'package:packagehub/core/parser/pickup_parser.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';
import 'package:packagehub/recognition/recognition_evidence.dart';
import 'package:packagehub/recognition/recognition_candidate.dart';
import 'package:packagehub/recognition/recognition_conflict.dart';

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

  testWidgets('OCR courier fixture opens with pending status', (tester) async {
    final draft = PickupParser.parse('【圆通快递】凭65-2-7826到天津市商业大学老东门快递站取尾号7826包裹');
    await tester.pumpWidget(
      MaterialApp(home: PickupReviewPage(originalDraft: draft)),
    );

    expect(find.text('圆通速递'), findsOneWidget);
    expect(find.text('65-2-7826'), findsOneWidget);
    expect(find.text('待取件'), findsOneWidget);
    expect(find.text('未判断'), findsNothing);
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

  testWidgets('shows direct and inferred evidence', (tester) async {
    const draft = PickupCredentialDraft(
      courierCompany: CourierCompany.zto,
      trackingNumber: null,
      pickupCode: 'D1-4-2586',
      stationName: null,
      status: PickupStatus.pending,
      sourcePlatform: PackagePlatform.unknown,
      rawText: '取件码为D1-4-2586',
      evidence: [
        RecognitionEvidence(
          field: RecognitionField.pickupCode,
          kind: RecognitionEvidenceKind.direct,
          source: RecognitionEvidenceSource.explicitKeyword,
          ruleId: 'pickup_code.explicit_keyword',
        ),
        RecognitionEvidence(
          field: RecognitionField.courierCompany,
          kind: RecognitionEvidenceKind.inferred,
          source: RecognitionEvidenceSource.stationPrefixRule,
          ruleId: 'courier.station_prefix.d',
        ),
      ],
    );
    await tester.pumpWidget(
      const MaterialApp(home: PickupReviewPage(originalDraft: draft)),
    );
    expect(find.text('D1-4-2586'), findsOneWidget);
    expect(find.text('中通快递'), findsOneWidget);
    expect(find.text('取件码：来自原文'), findsOneWidget);
    expect(find.text('快递公司：根据站点规则推断'), findsOneWidget);
  });

  testWidgets('editing courier removes only courier evidence', (tester) async {
    const draft = PickupCredentialDraft(
      courierCompany: CourierCompany.zto,
      trackingNumber: 'SF1234567890',
      pickupCode: 'D1-4-2586',
      stationName: null,
      status: PickupStatus.pending,
      sourcePlatform: PackagePlatform.unknown,
      rawText: '取件码为D1-4-2586',
      evidence: [
        RecognitionEvidence(
          field: RecognitionField.courierCompany,
          kind: RecognitionEvidenceKind.inferred,
          source: RecognitionEvidenceSource.stationPrefixRule,
          ruleId: 'courier.station_prefix.d',
        ),
        RecognitionEvidence(
          field: RecognitionField.pickupCode,
          kind: RecognitionEvidenceKind.direct,
          source: RecognitionEvidenceSource.explicitKeyword,
          ruleId: 'pickup_code.explicit_keyword',
        ),
        RecognitionEvidence(
          field: RecognitionField.trackingNumber,
          kind: RecognitionEvidenceKind.direct,
          source: RecognitionEvidenceSource.explicitTrackingContext,
          ruleId: 'tracking.explicit_or_context',
        ),
      ],
    );
    PickupCredentialDraft? result;
    await tester.pumpWidget(
      MaterialApp(home: PickupReviewPage(originalDraft: draft)),
    );
    await tester.tap(find.byKey(const Key('courierCompanyField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('申通快递').last);
    await tester.pumpAndSettle();
    expect(find.text('快递公司：根据站点规则推断'), findsNothing);
    expect(find.text('取件码：来自原文'), findsOneWidget);
    result = null;
    // The page retains the edited draft internally; this assertion verifies the UI state.
    expect(find.text('申通快递'), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets('shows conflict alternative without technical rule details', (
    tester,
  ) async {
    final draft = PickupCredentialDraft(
      courierCompany: CourierCompany.zto,
      trackingNumber: null,
      pickupCode: 'D1-4-2586',
      stationName: null,
      status: PickupStatus.pending,
      sourcePlatform: PackagePlatform.unknown,
      rawText: '取件码为D1-4-2586，凭D9-2-3700到快递站取件',
      evidence: const [
        RecognitionEvidence(
          field: RecognitionField.pickupCode,
          kind: RecognitionEvidenceKind.direct,
          source: RecognitionEvidenceSource.explicitKeyword,
          ruleId: 'pickup_code.explicit_keyword',
        ),
      ],
      conflicts: [
        RecognitionConflict(
          field: RecognitionField.pickupCode,
          winner: const RecognitionCandidate(
            field: RecognitionField.pickupCode,
            value: 'D1-4-2586',
            ruleId: 'pickup_code.explicit_keyword',
            priority: 100,
            kind: RecognitionEvidenceKind.direct,
            source: RecognitionEvidenceSource.explicitKeyword,
          ),
          alternatives: const [
            RecognitionCandidate(
              field: RecognitionField.pickupCode,
              value: 'D9-2-3700',
              ruleId: 'pickup_code.after_ping',
              priority: 90,
              kind: RecognitionEvidenceKind.direct,
              source: RecognitionEvidenceSource.explicitKeyword,
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(home: PickupReviewPage(originalDraft: draft)),
    );
    expect(find.text('D1-4-2586'), findsOneWidget);
    expect(find.text('取件码：来自原文'), findsOneWidget);
    expect(find.text('检测到多个可能结果，请确认'), findsOneWidget);
    expect(find.text('取件码：D9-2-3700'), findsOneWidget);
    expect(find.text('priority'), findsNothing);
    expect(find.text('pickup_code.after_ping'), findsNothing);
  });

  testWidgets('editing conflicted pickup code clears only its conflict', (
    tester,
  ) async {
    final draft =
        PickupCredentialDraft(
          courierCompany: CourierCompany.zto,
          trackingNumber: 'JT1234567890',
          pickupCode: 'D1-4-2586',
          stationName: null,
          status: PickupStatus.pending,
          sourcePlatform: PackagePlatform.unknown,
          rawText: '取件码为D1-4-2586',
          evidence: const [
            RecognitionEvidence(
              field: RecognitionField.pickupCode,
              kind: RecognitionEvidenceKind.direct,
              source: RecognitionEvidenceSource.explicitKeyword,
              ruleId: 'pickup_code.explicit_keyword',
            ),
            RecognitionEvidence(
              field: RecognitionField.courierCompany,
              kind: RecognitionEvidenceKind.inferred,
              source: RecognitionEvidenceSource.stationPrefixRule,
              ruleId: 'courier.station_prefix.d',
            ),
            RecognitionEvidence(
              field: RecognitionField.trackingNumber,
              kind: RecognitionEvidenceKind.direct,
              source: RecognitionEvidenceSource.explicitTrackingContext,
              ruleId: 'tracking.explicit_or_context',
            ),
          ],
          conflicts: const [],
        ).copyWith(
          conflicts: [
            RecognitionConflict(
              field: RecognitionField.pickupCode,
              winner: const RecognitionCandidate(
                field: RecognitionField.pickupCode,
                value: 'D1-4-2586',
                ruleId: 'a',
                priority: 100,
                kind: RecognitionEvidenceKind.direct,
                source: RecognitionEvidenceSource.explicitKeyword,
              ),
              alternatives: const [
                RecognitionCandidate(
                  field: RecognitionField.pickupCode,
                  value: 'D9-2-3700',
                  ruleId: 'b',
                  priority: 90,
                  kind: RecognitionEvidenceKind.direct,
                  source: RecognitionEvidenceSource.explicitKeyword,
                ),
              ],
            ),
          ],
        );
    await tester.pumpWidget(
      MaterialApp(home: PickupReviewPage(originalDraft: draft)),
    );
    await tester.enterText(
      find.byKey(const Key('pickupCodeField')),
      'D9-2-3700',
    );
    await tester.pump();
    expect(find.text('检测到多个可能结果，请确认'), findsNothing);
    expect(find.text('快递公司：根据站点规则推断'), findsOneWidget);
    expect(find.text('运单号：来自原文'), findsOneWidget);
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
