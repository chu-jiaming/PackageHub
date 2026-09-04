import 'package:packagehub/models/pickup_credential_draft.dart';
import 'package:packagehub/recognition/recognition_candidate.dart';
import 'package:packagehub/recognition/recognition_context.dart';
import 'package:packagehub/recognition/recognition_evidence.dart';
import 'package:packagehub/recognition/recognition_rule.dart';
import 'package:packagehub/recognition/recognition_rule_priority.dart';

const _patterns = <(CourierCompany, List<String>)>[
  (CourierCompany.sfExpress, ['顺丰速运', '顺丰', 'SF EXPRESS']),
  (CourierCompany.yto, ['圆通速递', '圆通']),
  (CourierCompany.zto, ['中通快递', '中通']),
  (CourierCompany.sto, ['申通快递', '申通']),
  (CourierCompany.yunda, ['韵达快递', '韵达']),
  (CourierCompany.jtexpress, ['极兔速递', '极兔', 'J&T EXPRESS', 'J&T']),
  (CourierCompany.ems, ['邮政EMS', 'EMS']),
  (CourierCompany.chinaPost, ['中国邮政', '邮政快递']),
  (CourierCompany.jdLogistics, ['京东物流', '京东快递']),
  (CourierCompany.deppon, ['德邦快递', '德邦']),
  (CourierCompany.cainiaoExpress, ['菜鸟速递']),
  (CourierCompany.bestExpress, ['百世快递', '百世']),
];

class CourierExplicitNameRule implements RecognitionRule {
  const CourierExplicitNameRule();
  @override
  String get id => 'courier.explicit_name';
  @override
  int get priority => RecognitionRulePriority.explicitStrong;
  @override
  RecognitionField get field => RecognitionField.courierCompany;
  @override
  RecognitionEvidenceKind get kind => RecognitionEvidenceKind.direct;

  @override
  List<RecognitionCandidate> evaluate(RecognitionContext context) {
    final result = <RecognitionCandidate>[];
    for (final (company, keywords) in _patterns) {
      for (final keyword in keywords) {
        final index = context.normalizedText.toUpperCase().indexOf(
          keyword.toUpperCase(),
        );
        if (index >= 0) {
          result.add(
            RecognitionCandidate(
              field: field,
              value: company,
              ruleId: id,
              priority: priority,
              kind: kind,
              source: RecognitionEvidenceSource.explicitCourierName,
              matchedText: context.normalizedText.substring(
                index,
                index + keyword.length,
              ),
            ),
          );
          break;
        }
      }
    }
    return result;
  }
}
