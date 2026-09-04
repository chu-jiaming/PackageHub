enum RecognitionField { pickupCode, courierCompany, trackingNumber }

enum RecognitionEvidenceKind { direct, inferred }

enum RecognitionEvidenceSource {
  explicitKeyword,
  appCardContext,
  explicitCourierName,
  explicitTrackingContext,
  stationPrefixRule,
  trackingPrefixRule,
}

class RecognitionEvidence {
  final RecognitionField field;
  final RecognitionEvidenceKind kind;
  final RecognitionEvidenceSource source;
  final String ruleId;
  final String? matchedText;
  final String? explanation;

  const RecognitionEvidence({
    required this.field,
    required this.kind,
    required this.source,
    required this.ruleId,
    this.matchedText,
    this.explanation,
  });
}
