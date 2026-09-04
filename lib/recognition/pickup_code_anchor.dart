import 'package:packagehub/recognition/recognition_candidate.dart';

/// Internal segmentation anchor. It is deliberately not persisted or exposed
/// to the review UI.
class PickupCodeAnchor {
  final String value;
  final int startOffset;
  final int endOffset;
  final int lineIndex;
  final String ruleId;
  final int priority;
  final String? matchedText;
  final RecognitionCandidate candidate;

  const PickupCodeAnchor({
    required this.value,
    required this.startOffset,
    required this.endOffset,
    required this.lineIndex,
    required this.ruleId,
    required this.priority,
    required this.matchedText,
    required this.candidate,
  });
}
