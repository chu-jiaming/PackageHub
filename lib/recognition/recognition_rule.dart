import 'package:packagehub/recognition/recognition_candidate.dart';
import 'package:packagehub/recognition/recognition_context.dart';
import 'package:packagehub/recognition/recognition_evidence.dart';

abstract interface class RecognitionRule {
  String get id;
  RecognitionField get field;
  int get priority;
  RecognitionEvidenceKind get kind;

  List<RecognitionCandidate> evaluate(RecognitionContext context);
}
