import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/core/parser/pickup_parser.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';
import 'package:packagehub/recognition/recognition_evidence.dart';

void main() {
  group('PickupParser', () {
    test(
      'parseAll extracts multiple credentials with local tracking context',
      () {
        final drafts = PickupParser.parseAll('''
【中通快递】
取件码为D1-4-2586
运单号731111111111
【申通快递】
凭326-4-6038到站取件
运单号777440230805597
''');

        expect(drafts, hasLength(2));
        expect(drafts[0].pickupCode, 'D1-4-2586');
        expect(drafts[0].courierCompany, CourierCompany.zto);
        expect(drafts[0].trackingNumber, '731111111111');
        expect(drafts[1].pickupCode, '326-4-6038');
        expect(drafts[1].courierCompany, CourierCompany.sto);
        expect(drafts[1].trackingNumber, '777440230805597');
        expect(
          drafts.every((draft) => draft.status == PickupStatus.pending),
          isTrue,
        );
      },
    );

    test(
      'parseAll safely shares one direct courier but does not share tracking',
      () {
        final drafts = PickupParser.parseAll('''
【中通快递】
您有两个包裹
取件码为D1-4-2586
运单号731111111111
取件码为D9-2-3700
''');

        expect(drafts, hasLength(2));
        expect(
          drafts.map((draft) => draft.courierCompany),
          everyElement(CourierCompany.zto),
        );
        expect(drafts[0].trackingNumber, '731111111111');
        expect(drafts[1].trackingNumber, isNull);
      },
    );

    test(
      'parseAll keeps compact competing pickup candidates as one conflict',
      () {
        final drafts = PickupParser.parseAll('取件码为D1-4-2586，凭D9-2-3700到快递站取件');

        expect(drafts, hasLength(1));
        expect(drafts.single.pickupCode, 'D1-4-2586');
        expect(drafts.single.conflicts, isNotEmpty);
      },
    );

    test('parseAll independently infers courier prefixes', () {
      final drafts = PickupParser.parseAll('''
取件码为D1-4-2586
取件码为X3-2-1234
''');

      expect(drafts, hasLength(2));
      expect(drafts[0].courierCompany, CourierCompany.zto);
      expect(drafts[1].courierCompany, CourierCompany.sto);
    });

    test('parseAll deduplicates the same normalized pickup anchor', () {
      final drafts = PickupParser.parseAll('''
取件码为D1-4-2586
详情：凭D1-4-2586到站取件
''');

      expect(drafts, hasLength(1));
      expect(drafts.single.pickupCode, 'D1-4-2586');
    });

    test('parses real pinduoduo OCR fixture without using tracking data', () {
      const rawText = '''
08:04
拼多多
已签收
物流服务
取件码 Z5-2-1350
兔喜快递超市代收点| 东门小院快递服务中心
您有 2个快递待取
复制
拨打电话
极兔速递：JT5519167631350
极兔快递派件员
订单编号：260823-255433131624042
收货地址：某市某区某道路
已签收 2026-08-29 14:51:05
包裹已签收！（凭取件码）
联系电话：13800000000
''';

      final draft = PickupParser.parse(rawText);

      expect(draft.sourcePlatform, PackagePlatform.pinduoduo);
      expect(draft.courierCompany, CourierCompany.jtexpress);
      expect(draft.trackingNumber, 'JT5519167631350');
      expect(draft.pickupCode, 'Z5-2-1350');
      expect(draft.stationName, '兔喜快递超市代收点 | 东门小院快递服务中心');
      expect(draft.status, PickupStatus.pending);
      expect(draft.pickupCode, isNot('JT5519167631350'));
      expect(draft.pickupCode, isNot('260823-255433131624042'));
      expect(draft.pickupCode, isNot('13800000000'));
      expect(draft.trackingNumber, isNot('260823-255433131624042'));
      expect(draft.trackingNumber, isNot('13800000000'));
    });

    test('parses pickup code after 取件码', () {
      final draft = PickupParser.parse('取件码 Z5-2-1350');

      expect(draft.pickupCode, 'Z5-2-1350');
    });

    test('parses pickup code after Chinese colon', () {
      final draft = PickupParser.parse('取件码：6-2-8-1');

      expect(draft.pickupCode, '6-2-8-1');
    });

    test('normalizes spaced dashes in pickup code', () {
      final draft = PickupParser.parse('取货码 A1 - 2 - 3456');

      expect(draft.pickupCode, 'A1-2-3456');
    });

    test('preserves ambiguous OCR letters in pickup code segment', () {
      final draft = PickupParser.parse('取件码 TO-2-1350');

      expect(draft.pickupCode, 'TO-2-1350');
      expect(draft.rawText, '取件码 TO-2-1350');
    });

    test('parses numeric identity code only with pickup context', () {
      final draft = PickupParser.parse('身份码 123456');

      expect(draft.pickupCode, '123456');
    });

    test(
      'does not parse tracking number order number or phone as pickup code',
      () {
        const rawText = '''
极兔速递 JT5519167631350
订单编号 123456789
手机号 13800000000
''';

        final draft = PickupParser.parse(rawText);

        expect(draft.courierCompany, CourierCompany.jtexpress);
        expect(draft.trackingNumber, 'JT5519167631350');
        expect(draft.pickupCode, isNull);
      },
    );

    test('keeps pending when pickup code and pending text coexist with signed text', () {
      const rawText = '''
取件码 12-3-4567
已签收
您有1个包裹待取
''';

      final draft = PickupParser.parse(rawText);

      expect(draft.pickupCode, '12-3-4567');
      expect(draft.status, PickupStatus.pending);
    });

    test('returns unknown draft for unrelated text', () {
      const rawText = '''
欢迎使用 PackageHub
今天没有新的消息
''';

      final draft = PickupParser.parse(rawText);

      expect(draft.sourcePlatform, PackagePlatform.unknown);
      expect(draft.courierCompany, CourierCompany.unknown);
      expect(draft.trackingNumber, isNull);
      expect(draft.pickupCode, isNull);
      expect(draft.stationName, isNull);
      expect(draft.status, PickupStatus.pending);
    });

    test('prioritizes shopping platform over cainiao keyword', () {
      final draft = PickupParser.parse('拼多多\n菜鸟驿站\n取件码 12-3-4567');

      expect(draft.sourcePlatform, PackagePlatform.pinduoduo);
    });

    test('recognizes taobao family jd and cainiao platforms', () {
      expect(
        PickupParser.parse('淘宝\n取件码 12-3-4567').sourcePlatform,
        PackagePlatform.taobao,
      );
      expect(
        PickupParser.parse('天猫\n取件码 12-3-4567').sourcePlatform,
        PackagePlatform.taobao,
      );
      expect(
        PickupParser.parse('淘特\n取件码 12-3-4567').sourcePlatform,
        PackagePlatform.taobao,
      );
      expect(
        PickupParser.parse('京东\n取件码 12-3-4567').sourcePlatform,
        PackagePlatform.jd,
      );
      expect(
        PickupParser.parse('菜鸟\n取件码 12-3-4567').sourcePlatform,
        PackagePlatform.cainiao,
      );
    });

    test('recognizes jtexpress courier and tracking number', () {
      final draft = PickupParser.parse('极兔速递：JT5519167631350');

      expect(draft.courierCompany, CourierCompany.jtexpress);
      expect(draft.trackingNumber, 'JT5519167631350');
    });

    test('recognizes sf express courier and tracking number', () {
      final draft = PickupParser.parse('顺丰速运 SF1234567890');

      expect(draft.courierCompany, CourierCompany.sfExpress);
      expect(draft.trackingNumber, 'SF1234567890');
    });

    test('recognizes common courier company names', () {
      expect(PickupParser.parse('圆通速递').courierCompany, CourierCompany.yto);
      expect(PickupParser.parse('中通快递').courierCompany, CourierCompany.zto);
      expect(PickupParser.parse('申通快递').courierCompany, CourierCompany.sto);
      expect(PickupParser.parse('韵达快递').courierCompany, CourierCompany.yunda);
      expect(
        PickupParser.parse('京东物流').courierCompany,
        CourierCompany.jdLogistics,
      );
      expect(PickupParser.parse('德邦快递').courierCompany, CourierCompany.deppon);
    });

    test('does not treat pickup networks as courier companies', () {
      expect(PickupParser.parse('菜鸟驿站').courierCompany, CourierCompany.unknown);
      expect(
        PickupParser.parse('兔喜快递超市代收点').courierCompany,
        CourierCompany.unknown,
      );
      expect(
        PickupParser.parse('丰巢智能柜').courierCompany,
        CourierCompany.unknown,
      );
    });

    test('recognizes cainiao express only from cainiao express keyword', () {
      expect(
        PickupParser.parse('菜鸟速递').courierCompany,
        CourierCompany.cainiaoExpress,
      );
    });

    test('does not use order number as tracking number', () {
      const rawText = '''
极兔速递
订单编号：260823-255433131624042
''';

      final draft = PickupParser.parse(rawText);

      expect(draft.courierCompany, CourierCompany.jtexpress);
      expect(draft.trackingNumber, isNull);
    });

    test('does not use phone number as tracking number', () {
      const rawText = '''
极兔速递
联系电话：13800000000
''';

      final draft = PickupParser.parse(rawText);

      expect(draft.courierCompany, CourierCompany.jtexpress);
      expect(draft.trackingNumber, isNull);
    });

    test('parses real SMS pickup-code fixtures', () {
      final cases = <({String text, String code, CourierCompany courier})>[
        (
          text: '【免喜生活】您有包裹已到达商业大学奥克米中心店，取件码为D1-4-2586，地址:东门小院快递服务中心',
          code: 'D1-4-2586',
          courier: CourierCompany.zto,
        ),
        (
          text: '【免喜生活】您有包裹已到达商业大学奥克米中心店，取件码为D9-2-3700，地址:东门小院快递服务中心',
          code: 'D9-2-3700',
          courier: CourierCompany.zto,
        ),
        (
          text: '【申通快递】凭326-4-6038到天津市商业大学老东门快递站取尾号6038包裹',
          code: '326-4-6038',
          courier: CourierCompany.sto,
        ),
        (
          text: '【圆通快递】凭65-2-7826到天津市商业大学老东门快递站取尾号7826包裹',
          code: '65-2-7826',
          courier: CourierCompany.yto,
        ),
        (
          text: '【极兔速递】凭96-3-0834到天津市商业大学老东门快递站取尾号0834包裹',
          code: '96-3-0834',
          courier: CourierCompany.jtexpress,
        ),
      ];

      for (final testCase in cases) {
        final draft = PickupParser.parse(testCase.text);
        expect(draft.pickupCode, testCase.code);
        expect(draft.courierCompany, testCase.courier);
      }
    });

    test('parses 凭 pickup code formatting variants', () {
      for (final text in [
        '凭 326-4-6038 到',
        '凭326 - 4 - 6038到',
        '凭326－4－6038到',
        '凭\n326-4-6038\n到',
        '凭：326-4-6038',
        '凭: 326-4-6038',
      ]) {
        expect(PickupParser.parse(text).pickupCode, '326-4-6038');
      }
    });

    test('requires pickup context for three-segment codes', () {
      expect(PickupParser.parse('订单号 326-4-6038').pickupCode, isNull);
      expect(PickupParser.parse('您的包裹取尾号6038').pickupCode, isNull);
      expect(PickupParser.parse('联系电话 +86 170 2950 0940').pickupCode, isNull);
      expect(PickupParser.parse('106804495000002').pickupCode, isNull);
    });

    test('infers courier from the shared station prefix rules', () {
      const expected = <String, CourierCompany>{
        'D1-4-2586': CourierCompany.zto,
        'D9-2-3700': CourierCompany.zto,
        'C1-2-3456': CourierCompany.zto,
        'T1-2-3456': CourierCompany.zto,
        'Z1-2-3456': CourierCompany.zto,
        'S1-2-3456': CourierCompany.jtexpress,
        'E1-2-3456': CourierCompany.yto,
        'R1-2-3456': CourierCompany.yto,
        'H1-2-3456': CourierCompany.yto,
        'L1-2-3456': CourierCompany.yto,
        'F1-2-3456': CourierCompany.ems,
        'X1-2-3456': CourierCompany.sto,
        'V1-2-3456': CourierCompany.yunda,
      };

      for (final entry in expected.entries) {
        expect(
          PickupParser.parse('取件码 ${entry.key}').courierCompany,
          entry.value,
        );
      }
      expect(
        PickupParser.parse('取件码 A1-2-3456').courierCompany,
        CourierCompany.unknown,
      );
      expect(
        PickupParser.parse('取件码 K1-2-3456').courierCompany,
        CourierCompany.unknown,
      );
      expect(
        PickupParser.parse('凭326-4-6038到').courierCompany,
        CourierCompany.unknown,
      );
    });

    test('explicit courier wins over prefix inference', () {
      expect(
        PickupParser.parse('申通快递\n取件码 D1-4-2586').courierCompany,
        CourierCompany.sto,
      );
      expect(
        PickupParser.parse('极兔速递\n取件码 Z5-2-1350').courierCompany,
        CourierCompany.jtexpress,
      );
      expect(
        PickupParser.parse('圆通快递\n取件码 X1-1-123').courierCompany,
        CourierCompany.yto,
      );
    });

    test('keyword pickup code wins over 凭 context and reports conflict', () {
      final draft = PickupParser.parse('取件码为D1-4-2586，凭D9-2-3700到快递站取件');
      expect(draft.pickupCode, 'D1-4-2586');
      expect(draft.conflicts, hasLength(1));
      expect(draft.conflicts.single.alternatives.single.value, 'D9-2-3700');
    });

    test('same pickup code from keyword and 凭 context is not a conflict', () {
      final draft = PickupParser.parse('取件码为D1-4-2586，凭D1-4-2586到快递站取件');
      expect(draft.pickupCode, 'D1-4-2586');
      expect(draft.conflicts, isEmpty);
    });

    test('multiple explicit courier names conflict and block inference', () {
      final draft = PickupParser.parse('【申通快递】【圆通快递】取件码为X1-2-3456');
      // The registry's stable courier pattern order makes 圆通 the winner.
      expect(draft.courierCompany, CourierCompany.yto);
      expect(draft.conflicts.single.field, RecognitionField.courierCompany);
      expect(
        draft.evidence.where((e) => e.field == RecognitionField.courierCompany),
        hasLength(1),
      );
      expect(
        draft.evidence
            .where((e) => e.field == RecognitionField.courierCompany)
            .single
            .kind,
        RecognitionEvidenceKind.direct,
      );
    });

    test('registry has stable direct order', () {
      final ids = PickupParser.ruleRegistry.directRules
          .map((rule) => rule.id)
          .toList();
      expect(
        ids.indexOf('pickup_code.explicit_keyword'),
        lessThan(ids.indexOf('pickup_code.after_ping')),
      );
    });

    test('OCR logistics status phrases never change the new draft status', () {
      for (final text in [
        '您的包裹已签收，取件码为D1-4-2586',
        '包裹已送达快递站，取件码为D1-4-2586',
        '包裹已入库，请取件',
        '订单已完成',
        '已取件',
      ]) {
        expect(PickupParser.parse(text).status, PickupStatus.pending);
      }
    });

    test('weak OCR still creates a pending draft', () {
      final draft = PickupParser.parse('没有可识别的物流字段');
      expect(draft.status, PickupStatus.pending);
      expect(draft.courierCompany, CourierCompany.unknown);
      expect(draft.pickupCode, isNull);
      expect(draft.trackingNumber, isNull);
    });

    test('recognizes a pickup code shown directly in one app card', () {
      const rawText = '''
临时场地1|校内申通快递＞查看地址
申通
519-3-9180
今日到站 查单号添加
申通 777440538759180
好友代取
跑腿送货
''';

      final draft = PickupParser.parseAll(rawText).single;

      expect(draft.pickupCode, '519-3-9180');
      expect(draft.courierCompany, CourierCompany.sto);
      expect(draft.trackingNumber, '777440538759180');
      expect(draft.status, PickupStatus.pending);
      final pickupEvidence = draft.evidence.singleWhere(
        (evidence) => evidence.field == RecognitionField.pickupCode,
      );
      expect(pickupEvidence.kind, RecognitionEvidenceKind.direct);
      expect(pickupEvidence.ruleId, 'pickup_code.app_card_context');
      expect(pickupEvidence.matchedText, '519-3-9180');
    });

    test('recognizes app cards with bounded arrived-time cues', () {
      for (final arrival in ['已到站1小时', '已到站30分钟', '已到站']) {
        final draft = PickupParser.parse('''600-3-8599
$arrival
极兔速递''');

        expect(draft.pickupCode, '600-3-8599', reason: arrival);
        expect(draft.courierCompany, CourierCompany.jtexpress, reason: arrival);
        expect(draft.trackingNumber, isNull, reason: arrival);
        expect(draft.status, PickupStatus.pending, reason: arrival);
        expect(
          draft.evidence
              .singleWhere(
                (evidence) => evidence.field == RecognitionField.pickupCode,
              )
              .ruleId,
          'pickup_code.app_card_context',
          reason: arrival,
        );
        final courierEvidence = draft.evidence.singleWhere(
          (evidence) => evidence.field == RecognitionField.courierCompany,
        );
        expect(courierEvidence.kind, RecognitionEvidenceKind.direct);
        expect(
          courierEvidence.source,
          RecognitionEvidenceSource.explicitCourierName,
        );
      }
    });

    test('recognizes an app card with the confirmed operation cue', () {
      final draft = PickupParser.parse('''600-3-8599
极兔速递
找人帮取''');

      expect(draft.pickupCode, '600-3-8599');
      expect(draft.courierCompany, CourierCompany.jtexpress);
      expect(draft.trackingNumber, isNull);
    });

    test('does not promote a bare three-part code without app card cues', () {
      final draft = PickupParser.parse('订单编号\n600-3-8599\n商品信息');

      expect(draft.pickupCode, isNull);
    });

    test('recognizes two app cards with local tracking and YT fallback', () {
      const rawText = '''
天津商业大学新菜乌驿站
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
跑腿送货
''';

      final drafts = PickupParser.parseAll(rawText);

      expect(drafts, hasLength(2));
      expect(drafts.map((draft) => draft.pickupCode), [
        '28-2-4367',
        '519-3-9180',
      ]);
      expect(drafts[0].courierCompany, CourierCompany.yto);
      expect(drafts[0].trackingNumber, 'YT8897917364367');
      expect(drafts[1].courierCompany, CourierCompany.sto);
      expect(drafts[1].trackingNumber, '777440538750180');
      expect(
        drafts.every((draft) => draft.status == PickupStatus.pending),
        isTrue,
      );
      final inferredCourier = drafts[0].evidence.singleWhere(
        (evidence) => evidence.field == RecognitionField.courierCompany,
      );
      expect(inferredCourier.kind, RecognitionEvidenceKind.inferred);
      expect(inferredCourier.ruleId, 'courier.tracking_prefix.yt');
      expect(
        inferredCourier.source,
        RecognitionEvidenceSource.trackingPrefixRule,
      );
      expect(inferredCourier.matchedText, 'YT8897917364367');
    });

    test('does not promote a bare app-shaped code without card context', () {
      final draft = PickupParser.parse('订单备注\n519-3-9180\n谢谢');

      expect(draft.pickupCode, isNull);
    });

    test('does not promote a phone-shaped three-segment number', () {
      final draft = PickupParser.parse('联系电话\n170-2950-0940\n好友代取');

      expect(draft.pickupCode, isNull);
    });

    test('explicit courier wins over YT tracking-prefix inference', () {
      final draft = PickupParser.parse('''
申通
519-3-9180
今日到站
申通 YT8897917364367
''');

      expect(draft.courierCompany, CourierCompany.sto);
      expect(
        draft.evidence
            .where(
              (evidence) => evidence.field == RecognitionField.courierCompany,
            )
            .single
            .kind,
        RecognitionEvidenceKind.direct,
      );
    });

    test('same app code from explicit and app-card rules is deduplicated', () {
      final draft = PickupParser.parse('''
取件码为519-3-9180
今日到站
好友代取
''');

      expect(draft.pickupCode, '519-3-9180');
      expect(draft.conflicts, isEmpty);
      expect(
        draft.evidence
            .where((evidence) => evidence.field == RecognitionField.pickupCode)
            .single
            .ruleId,
        'pickup_code.explicit_keyword',
      );
    });
  });
}
