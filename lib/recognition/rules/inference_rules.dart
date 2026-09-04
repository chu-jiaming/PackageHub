import 'package:packagehub/map/station_pickup_rules.dart';
import 'package:packagehub/recognition/recognition_candidate.dart';
import 'package:packagehub/recognition/recognition_context.dart';
import 'package:packagehub/recognition/recognition_evidence.dart';
import 'package:packagehub/recognition/recognition_rule.dart';
import 'package:packagehub/recognition/recognition_rule_priority.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

class CourierStationPrefixInferenceRule implements RecognitionRule {
  const CourierStationPrefixInferenceRule();
  @override
  String get id => 'courier.station_prefix';
  @override
  int get priority => RecognitionRulePriority.inference;
  @override
  RecognitionField get field => RecognitionField.courierCompany;
  @override
  RecognitionEvidenceKind get kind => RecognitionEvidenceKind.inferred;

  @override
  List<RecognitionCandidate> evaluate(RecognitionContext context) {
    final code = context.currentPickupCode;
    final company = StationPickupRules.resolveCourierFromPickupCode(code);
    if (code == null || code.isEmpty || company == null) return const [];
    final prefix = code[0].toUpperCase();
    return [
      RecognitionCandidate(
        field: field,
        value: company,
        ruleId: '$id.${prefix.toLowerCase()}',
        priority: priority,
        kind: kind,
        source: RecognitionEvidenceSource.stationPrefixRule,
        matchedText: prefix,
        explanation: '根据当前站点规则：$prefix 开头 → ${company.displayName}',
      ),
    ];
  }
}

class CourierTrackingPrefixInferenceRule implements RecognitionRule {
  const CourierTrackingPrefixInferenceRule();

  @override
  String get id => 'courier.tracking_prefix.yt';
  @override
  int get priority => RecognitionRulePriority.inference;
  @override
  RecognitionField get field => RecognitionField.courierCompany;
  @override
  RecognitionEvidenceKind get kind => RecognitionEvidenceKind.inferred;

  @override
  List<RecognitionCandidate> evaluate(RecognitionContext context) {
    final tracking = RegExp(r'\bYT\d[A-Za-z0-9]{7,25}\b', caseSensitive: false);
    for (final line in context.lines) {
      final match = tracking.firstMatch(line);
      if (match == null) continue;
      return [
        RecognitionCandidate(
          field: field,
          value: CourierCompany.yto,
          ruleId: id,
          priority: priority,
          kind: kind,
          source: RecognitionEvidenceSource.trackingPrefixRule,
          matchedText: match.group(0),
          explanation: '根据运单号前缀 YT 推断为圆通',
        ),
      ];
    }
    return const [];
  }
}
