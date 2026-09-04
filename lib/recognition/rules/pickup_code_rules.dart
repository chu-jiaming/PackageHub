import 'package:packagehub/core/parser/pickup_parser.dart';
import 'package:packagehub/recognition/recognition_candidate.dart';
import 'package:packagehub/recognition/recognition_context.dart';
import 'package:packagehub/recognition/recognition_evidence.dart';
import 'package:packagehub/recognition/recognition_rule.dart';
import 'package:packagehub/recognition/recognition_rule_priority.dart';

final _keywordPattern = RegExp(
  r'(?:取件码|取货码|提货码|自提码|身份码|开柜码)\s*(?:为|是)?\s*[：:]?\s*([A-Za-z0-9]+(?:\s*-[\s]*[A-Za-z0-9]+)*)',
);
final _pingPattern = RegExp(
  r'凭\s*[：:]?\s*([A-Za-z0-9]+(?:\s*-[\s]*\d+){2})(?=\s*(?:到|$))',
);
final _appCardCodePattern = RegExp(
  r'(?<![A-Za-z0-9])([A-Za-z0-9]+-\d{1,2}-\d{3,8})(?![A-Za-z0-9])',
);
const _arrivalCues = ['今日到站', '今日到达', '今日到店', '今日到品', '今日期品'];
final _arrivalCuePattern = RegExp(
  r'(?:今日到站|今日到达|今日到店|今日到品|今日期品|已到站(?:\d+(?:分钟|小时))?(?!\d|分钟|小时|天))',
);
const _actionCues = ['好友代取', '跑腿送货', '实景找包裹', '查询取件码', '查单号', '单号添加', '找人帮取'];
final _courierCue = RegExp(r'顺丰|圆通|中通|申通|韵达|极兔|邮政|京东|德邦');
final _trackingCue = RegExp(r'[A-Za-z]{1,4}\d[A-Za-z0-9]{7,25}|\d{10,18}');

abstract class _PickupCodeRule implements RecognitionRule {
  const _PickupCodeRule();

  RecognitionCandidate? candidate(
    String code,
    String matchedText, {
    RecognitionEvidenceSource source =
        RecognitionEvidenceSource.explicitKeyword,
  }) {
    final value = PickupParser.normalizePickupCode(code);
    if (!_valid(value)) return null;
    return RecognitionCandidate(
      field: RecognitionField.pickupCode,
      value: value,
      ruleId: id,
      priority: priority,
      kind: kind,
      source: source,
      matchedText: matchedText,
    );
  }

  bool _valid(String code) =>
      code.length >= 3 &&
      code.length <= 14 &&
      RegExp(r'^[A-Za-z0-9]+(?:-[A-Za-z0-9]+)*$').hasMatch(code) &&
      RegExp(r'\d').hasMatch(code) &&
      !RegExp(r'^1\d{10}$').hasMatch(code.replaceAll('-', ''));
}

/// Recognizes the short code shown as the primary token in a parcel card.
/// The shape alone is insufficient; the bounded local window must contain a
/// deterministic parcel-card cue.
class AppCardPickupCodeRule extends _PickupCodeRule {
  const AppCardPickupCodeRule();

  @override
  String get id => 'pickup_code.app_card_context';
  @override
  int get priority => RecognitionRulePriority.explicitContext;
  @override
  RecognitionField get field => RecognitionField.pickupCode;
  @override
  RecognitionEvidenceKind get kind => RecognitionEvidenceKind.direct;

  @override
  List<RecognitionCandidate> evaluate(RecognitionContext context) {
    final result = <RecognitionCandidate>[];
    for (var lineIndex = 0; lineIndex < context.lines.length; lineIndex++) {
      final line = context.lines[lineIndex];
      for (final match in _appCardCodePattern.allMatches(line)) {
        final code = match.group(1);
        if (code == null || !_isCodeLine(line, code)) continue;
        final start = (lineIndex - 3).clamp(0, context.lines.length - 1);
        final end = (lineIndex + 5).clamp(0, context.lines.length - 1);
        final window = context.lines.sublist(start, end + 1);
        final hasArrival = window.any(
          (item) =>
              _arrivalCues.any(item.contains) ||
              _arrivalCuePattern.hasMatch(item),
        );
        final hasAction = window.any((item) => _actionCues.any(item.contains));
        final hasCourierAndTracking =
            window.any((item) => _courierCue.hasMatch(item)) &&
            window.any((item) => _trackingCue.hasMatch(item));
        if (!hasArrival && !hasAction && !hasCourierAndTracking) continue;
        final item = candidate(
          code,
          code,
          source: RecognitionEvidenceSource.appCardContext,
        );
        if (item != null) result.add(item);
      }
    }
    return result;
  }

  bool _isCodeLine(String line, String code) {
    final trimmed = line.trim();
    return trimmed == code ||
        (trimmed.length <= code.length + 12 && trimmed.contains(code));
  }
}

class PickupCodeExplicitKeywordRule extends _PickupCodeRule {
  const PickupCodeExplicitKeywordRule();
  @override
  String get id => 'pickup_code.explicit_keyword';
  @override
  int get priority => RecognitionRulePriority.explicitStrong;
  @override
  RecognitionField get field => RecognitionField.pickupCode;
  @override
  RecognitionEvidenceKind get kind => RecognitionEvidenceKind.direct;
  @override
  List<RecognitionCandidate> evaluate(RecognitionContext context) {
    final result = <RecognitionCandidate>[];
    for (final match in _keywordPattern.allMatches(context.normalizedText)) {
      final code = match.group(1);
      if (code == null) continue;
      final item = candidate(code, match.group(0)!);
      if (item != null) result.add(item);
    }
    return result;
  }
}

class PickupCodeAfterPingRule extends _PickupCodeRule {
  const PickupCodeAfterPingRule();
  @override
  String get id => 'pickup_code.after_ping';
  @override
  int get priority => RecognitionRulePriority.explicitContext;
  @override
  RecognitionField get field => RecognitionField.pickupCode;
  @override
  RecognitionEvidenceKind get kind => RecognitionEvidenceKind.direct;
  @override
  List<RecognitionCandidate> evaluate(RecognitionContext context) {
    final result = <RecognitionCandidate>[];
    for (final match in _pingPattern.allMatches(context.normalizedText)) {
      final code = match.group(1);
      if (code == null) continue;
      final item = candidate(code, match.group(0)!);
      if (item != null) result.add(item);
    }
    return result;
  }
}
