import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/core/parser/pickup_parser.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';
import 'package:packagehub/recognition/diagnostics/recognition_diagnostic_report.dart';
import 'package:packagehub/recognition/recognition_evidence.dart';
import 'package:packagehub/recognition/recognition_rule_priority.dart';

import 'recognition_fixtures.dart';

const fixtures = <RecognitionFixture>[
  RecognitionFixture(
    id: 'd1-station',
    description: 'D1 station inference',
    rawText: '天津某大学快递站\n取件码为D1-4-2586',
    expectedAnchorCount: 1,
    expectedCredentials: [
      ExpectedCredential(
        courierCompany: CourierCompany.zto,
        pickupCode: 'D1-4-2586',
        ruleIds: ['pickup_code.explicit_keyword', 'courier.station_prefix.d'],
      ),
    ],
  ),
  RecognitionFixture(
    id: 'app-card-sto',
    description: 'single app card',
    rawText: '校内申通快递\n申通\n519-3-9180\n申通 777440538759180',
    expectedAnchorCount: 1,
    expectedCredentials: [
      ExpectedCredential(
        courierCompany: CourierCompany.sto,
        pickupCode: '519-3-9180',
        trackingNumber: '777440538759180',
        ruleIds: ['pickup_code.app_card_context'],
      ),
    ],
  ),
  RecognitionFixture(
    id: 'multi-card',
    description: 'two local app cards',
    rawText: '''天津商业大学新菜乌驿站
28-2-4367
今日到品
单号添加
回通 YT8897917364367
还有包裹未显示？查询取件码
实景找包裹
好友代取
跑腿送货
临时场地1|校内申通快递
申通
519-3-9180
今日期品
单号添加
申通 777440538750180
好友代取
跑腿送货''',
    expectedAnchorCount: 2,
    expectedCredentials: [
      ExpectedCredential(
        courierCompany: CourierCompany.yto,
        pickupCode: '28-2-4367',
        trackingNumber: 'YT8897917364367',
      ),
      ExpectedCredential(
        courierCompany: CourierCompany.sto,
        pickupCode: '519-3-9180',
        trackingNumber: '777440538750180',
      ),
    ],
  ),
  RecognitionFixture(
    id: 'app-card-arrived-hours-jitu',
    description: 'app card with arrived-hours cue and direct J&T courier',
    rawText: '''某大学快递站
600-3-8599
已到站1小时 | 极兔速递
自行车锁
找人帮取''',
    expectedAnchorCount: 1,
    expectedCredentials: [
      ExpectedCredential(
        courierCompany: CourierCompany.jtexpress,
        pickupCode: '600-3-8599',
        trackingNumber: null,
        ruleIds: ['pickup_code.app_card_context', 'courier.explicit_name'],
      ),
    ],
  ),
  RecognitionFixture(
    id: 'compact-conflict',
    description: 'tight competing codes',
    rawText: '取件码为D1-4-2586，凭D9-2-3700到快递站取件',
    expectedAnchorCount: 2,
    expectedConflictCount: 1,
    expectedCredentials: [
      ExpectedCredential(
        courierCompany: CourierCompany.zto,
        pickupCode: 'D1-4-2586',
      ),
    ],
  ),
];

void main() {
  test('fixture runner covers stable recognition cases', () {
    for (final fixture in fixtures.take(4)) {
      expectRecognitionFixture(fixture);
    }
  });

  test('diagnostic runner exposes anchors, segments and conflicts', () {
    for (final fixture in fixtures) {
      expectDiagnosticFixture(fixture);
    }
    final result = PickupParser.parseAllWithDiagnostics(fixtures[2].rawText);
    expect(result.diagnostics.segmentCount, 2);
    expect(result.diagnostics.credentials, hasLength(2));
    expect(
      result.diagnostics.credentials[0].draft.trackingNumber,
      'YT88*******4367',
    );
    expect(
      RecognitionDiagnosticFormatter.format(result.diagnostics),
      contains('tracking_association: local'),
    );
    final appCard = PickupParser.parseAllWithDiagnostics(fixtures[3].rawText);
    expect(appCard.diagnostics.anchorCount, 1);
    expect(appCard.diagnostics.segmentCount, 1);
    expect(appCard.diagnostics.credentialCount, 1);
    expect(
      appCard
          .diagnostics
          .credentials
          .single
          .winners[RecognitionField.pickupCode]
          ?.ruleId,
      'pickup_code.app_card_context',
    );
    expect(appCard.diagnostics.credentials.single.trackingAssociation, 'none');
    expect(appCard.drafts.single.trackingNumber, isNull);
    expect(appCard.diagnostics.conflictCount, 0);
  });

  test('default registry rule ids and priorities are auditable', () {
    final rules = [
      ...PickupParser.ruleRegistry.directRules,
      ...PickupParser.ruleRegistry.inferenceRules,
    ];
    expect(rules.map((r) => r.id).toSet(), hasLength(rules.length));
    expect(rules.every((r) => [100, 90, 80, 10].contains(r.priority)), isTrue);
    expect(RecognitionRulePriority.explicitStrong, 100);
  });

  test(
    'fixture sanitizer masks phone and long tracking but preserves core fields',
    () {
      final sanitized = RecognitionFixtureSanitizer.sanitize(
        '申通 取件码519-3-9180 联系电话 +86 170 2950 0940 运单号777440538759180',
      );
      expect(sanitized, contains('申通'));
      expect(sanitized, contains('519-3-9180'));
      expect(sanitized, contains('<PHONE>'));
      expect(sanitized, contains('<TRACKING>'));
    },
  );
}
