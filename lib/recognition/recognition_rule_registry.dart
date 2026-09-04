import 'package:packagehub/recognition/recognition_rule.dart';
import 'package:packagehub/recognition/rules/courier_rules.dart';
import 'package:packagehub/recognition/rules/inference_rules.dart';
import 'package:packagehub/recognition/rules/pickup_code_rules.dart';
import 'package:packagehub/recognition/rules/tracking_rules.dart';

class RecognitionRuleRegistry {
  final List<RecognitionRule> directRules;
  final List<RecognitionRule> inferenceRules;

  const RecognitionRuleRegistry({
    required this.directRules,
    required this.inferenceRules,
  });

  factory RecognitionRuleRegistry.defaultRegistry() => RecognitionRuleRegistry(
    directRules: const [
      PickupCodeExplicitKeywordRule(),
      PickupCodeAfterPingRule(),
      AppCardPickupCodeRule(),
      CourierExplicitNameRule(),
      TrackingExplicitRule(),
    ],
    inferenceRules: const [
      CourierStationPrefixInferenceRule(),
      CourierTrackingPrefixInferenceRule(),
    ],
  );
}
