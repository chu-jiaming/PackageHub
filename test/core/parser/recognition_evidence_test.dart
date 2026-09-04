import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/core/parser/pickup_parser.dart';
import 'package:packagehub/recognition/recognition_evidence.dart';

void main() {
  test('infers D courier with direct pickup evidence', () {
    final draft = PickupParser.parse('【免喜生活】取件码为D1-4-2586');
    expect(draft.pickupCode, 'D1-4-2586');
    expect(draft.courierCompany.name, 'zto');
    expect(
      draft.evidence,
      contains(
        predicate<RecognitionEvidence>(
          (e) =>
              e.field == RecognitionField.pickupCode &&
              e.kind == RecognitionEvidenceKind.direct,
        ),
      ),
    );
    final courier = draft.evidence
        .where((e) => e.field == RecognitionField.courierCompany)
        .single;
    expect(courier.kind, RecognitionEvidenceKind.inferred);
    expect(courier.ruleId, 'courier.station_prefix.d');
    expect(courier.matchedText, 'D');
  });

  test('explicit courier prevents inference', () {
    final draft = PickupParser.parse('【申通快递】\n取件码为D1-4-2586');
    expect(draft.courierCompany.name, 'sto');
    expect(
      draft.evidence.where((e) => e.field == RecognitionField.courierCompany),
      everyElement((e) => e.kind == RecognitionEvidenceKind.direct),
    );
  });

  test('credential pickup code has a short direct matched fragment', () {
    final draft = PickupParser.parse(
      '【申通快递】凭326-4-6038到天津市商业大学老东门快递站取尾号6038包裹',
    );
    final pickup = draft.evidence
        .where((e) => e.field == RecognitionField.pickupCode)
        .single;
    expect(pickup.kind, RecognitionEvidenceKind.direct);
    expect(pickup.matchedText, '凭326-4-6038');
    expect(pickup.matchedText!.length, lessThan(draft.rawText.length));
  });
}
