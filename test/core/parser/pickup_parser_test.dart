import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/core/parser/pickup_parser.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

void main() {
  group('PickupParser', () {
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

      expect(draft.platform, PackagePlatform.pinduoduo);
      expect(draft.pickupCode, 'Z5-2-1350');
      expect(draft.stationName, '兔喜快递超市代收点 | 东门小院快递服务中心');
      expect(draft.status, PickupStatus.pending);
      expect(draft.pickupCode, isNot('JT5519167631350'));
      expect(draft.pickupCode, isNot('260823-255433131624042'));
      expect(draft.pickupCode, isNot('13800000000'));
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

    test('normalizes OCR confusion from T0 to TO in pickup code segment', () {
      final draft = PickupParser.parse('取件码 TO-2-1350');

      expect(draft.pickupCode, 'T0-2-1350');
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

      expect(draft.platform, PackagePlatform.unknown);
      expect(draft.pickupCode, isNull);
      expect(draft.stationName, isNull);
      expect(draft.status, PickupStatus.unknown);
    });

    test('prioritizes shopping platform over cainiao keyword', () {
      final draft = PickupParser.parse('拼多多\n菜鸟驿站\n取件码 12-3-4567');

      expect(draft.platform, PackagePlatform.pinduoduo);
    });

    test('recognizes taobao family jd and cainiao platforms', () {
      expect(
        PickupParser.parse('淘宝\n取件码 12-3-4567').platform,
        PackagePlatform.taobao,
      );
      expect(
        PickupParser.parse('天猫\n取件码 12-3-4567').platform,
        PackagePlatform.taobao,
      );
      expect(
        PickupParser.parse('淘特\n取件码 12-3-4567').platform,
        PackagePlatform.taobao,
      );
      expect(
        PickupParser.parse('京东\n取件码 12-3-4567').platform,
        PackagePlatform.jd,
      );
      expect(
        PickupParser.parse('菜鸟\n取件码 12-3-4567').platform,
        PackagePlatform.cainiao,
      );
    });
  });
}
