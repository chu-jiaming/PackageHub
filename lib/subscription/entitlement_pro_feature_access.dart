import 'pro_feature.dart';
import 'pro_feature_access.dart';
import 'subscription_repository.dart';

class EntitlementProFeatureAccess implements ProFeatureAccess {
  final SubscriptionRepository subscriptionRepository;

  const EntitlementProFeatureAccess(this.subscriptionRepository);

  @override
  bool canUse(ProFeature feature) => subscriptionRepository.current.isPro;

  @override
  int? get activeCredentialLimit =>
      subscriptionRepository.current.isPro ? null : 3;
}
