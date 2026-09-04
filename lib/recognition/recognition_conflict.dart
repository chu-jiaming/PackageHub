import 'package:packagehub/recognition/recognition_candidate.dart';
import 'package:packagehub/recognition/recognition_evidence.dart';

class RecognitionConflict {
  final RecognitionField field;
  final RecognitionCandidate winner;
  final List<RecognitionCandidate> alternatives;

  const RecognitionConflict({
    required this.field,
    required this.winner,
    required this.alternatives,
  });
}
