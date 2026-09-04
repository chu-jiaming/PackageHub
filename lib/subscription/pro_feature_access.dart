import 'pro_feature.dart';

abstract interface class ProFeatureAccess {
  bool canUse(ProFeature feature);

  int? get activeCredentialLimit;
}
