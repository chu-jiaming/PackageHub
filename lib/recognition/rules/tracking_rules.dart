import 'package:packagehub/recognition/recognition_candidate.dart';
import 'package:packagehub/recognition/recognition_context.dart';
import 'package:packagehub/recognition/recognition_evidence.dart';
import 'package:packagehub/recognition/recognition_rule.dart';
import 'package:packagehub/recognition/recognition_rule_priority.dart';

final _keyword = RegExp(r'(?:运单号|快递单号|物流单号)\s*[：:]?\s*([A-Za-z0-9]{8,30})');
final _candidate = RegExp(r'[A-Za-z]{1,4}\d[A-Za-z0-9]{7,25}|\d{10,18}');
final _phone = RegExp(r'^1[3-9]\d{9}$');

class TrackingExplicitRule implements RecognitionRule {
  const TrackingExplicitRule();
  @override
  String get id => 'tracking.explicit_or_context';
  @override
  int get priority => RecognitionRulePriority.explicitStrong;
  @override
  RecognitionField get field => RecognitionField.trackingNumber;
  @override
  RecognitionEvidenceKind get kind => RecognitionEvidenceKind.direct;

  @override
  List<RecognitionCandidate> evaluate(RecognitionContext context) {
    final result = <RecognitionCandidate>[];
    for (final line in context.lines) {
      if (line.contains('订单编号') ||
          line.contains('订单号') ||
          line.contains('手机号') ||
          line.contains('联系电话') ||
          line.contains('电话')) {
        continue;
      }
      final matches = _keyword.allMatches(line).toList();
      final values = matches.isNotEmpty
          ? matches.map((m) => (m.group(1)!, m.group(0)!))
          : _candidate.allMatches(line).map((m) => (m.group(0)!, m.group(0)!));
      for (final (value, matched) in values) {
        if (value.length < 8 || _phone.hasMatch(value)) continue;
        result.add(
          RecognitionCandidate(
            field: field,
            value: value.trim(),
            ruleId: id,
            priority: priority,
            kind: kind,
            source: RecognitionEvidenceSource.explicitTrackingContext,
            matchedText: matched,
          ),
        );
      }
    }
    return result;
  }
}
