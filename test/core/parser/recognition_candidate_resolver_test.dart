import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/recognition/recognition_candidate.dart';
import 'package:packagehub/recognition/recognition_candidate_resolver.dart';
import 'package:packagehub/recognition/recognition_evidence.dart';

RecognitionCandidate candidate(String value, int priority) =>
    RecognitionCandidate(
      field: RecognitionField.pickupCode,
      value: value,
      ruleId: value,
      priority: priority,
      kind: RecognitionEvidenceKind.direct,
      source: RecognitionEvidenceSource.explicitKeyword,
    );

void main() {
  const resolver = RecognitionCandidateResolver();

  test('higher priority wins and different value is a conflict', () {
    final result = resolver.resolve([
      candidate('D1', 100),
      candidate('D9', 90),
    ]);
    expect(result.winners[RecognitionField.pickupCode]!.value, 'D1');
    expect(result.conflicts.single.alternatives.single.value, 'D9');
  });

  test('same priority uses stable registration order', () {
    final result = resolver.resolve([
      candidate('D1', 100),
      candidate('D9', 100),
    ]);
    expect(result.winners[RecognitionField.pickupCode]!.value, 'D1');
    expect(result.conflicts.single.alternatives.single.value, 'D9');
  });

  test('same normalized value is not a conflict', () {
    final result = resolver.resolve([
      candidate('D1-4-2586', 100),
      candidate('D1-4-2586', 90),
    ]);
    expect(result.winners[RecognitionField.pickupCode]!.value, 'D1-4-2586');
    expect(result.conflicts, isEmpty);
  });

  test('conflicts are isolated by field', () {
    final courier = RecognitionCandidate(
      field: RecognitionField.courierCompany,
      value: 'sto',
      ruleId: 'courier.a',
      priority: 100,
      kind: RecognitionEvidenceKind.direct,
      source: RecognitionEvidenceSource.explicitCourierName,
    );
    final result = resolver.resolve([
      candidate('D1', 100),
      candidate('D9', 90),
      courier,
    ]);
    expect(result.conflicts.single.field, RecognitionField.pickupCode);
    expect(
      result.winners.keys,
      containsAll([
        RecognitionField.pickupCode,
        RecognitionField.courierCompany,
      ]),
    );
  });
}
