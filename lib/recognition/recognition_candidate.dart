import 'package:packagehub/recognition/recognition_evidence.dart';

class RecognitionCandidate {
  final RecognitionField field;
  final Object value;
  final String ruleId;
  final int priority;
  final RecognitionEvidenceKind kind;
  final RecognitionEvidenceSource source;
  final String? matchedText;
  final String? explanation;

  const RecognitionCandidate({
    required this.field,
    required this.value,
    required this.ruleId,
    required this.priority,
    required this.kind,
    required this.source,
    this.matchedText,
    this.explanation,
  });

  RecognitionEvidence toEvidence() => RecognitionEvidence(
    field: field,
    kind: kind,
    source: source,
    ruleId: ruleId,
    matchedText: matchedText,
    explanation: explanation,
  );
}
