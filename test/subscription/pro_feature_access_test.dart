import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/subscription/entitlement_pro_feature_access.dart';
import 'package:packagehub/subscription/mock_subscription_repository.dart';
import 'package:packagehub/subscription/pro_feature.dart';
import 'package:packagehub/subscription/subscription_entitlement.dart';
import 'package:packagehub/subscription/subscription_state.dart';

void main() {
  for (final state in [
    SubscriptionState.active,
    SubscriptionState.trial,
    SubscriptionState.gracePeriod,
    SubscriptionState.billingRetry,
  ]) {
    test('$state grants Pro feature access', () {
      final access = EntitlementProFeatureAccess(
        MockSubscriptionRepository(
          current: SubscriptionEntitlement(state: state),
        ),
      );
      expect(access.activeCredentialLimit, isNull);
      expect(access.canUse(ProFeature.unlimitedActiveCredentials), isTrue);
      expect(access.canUse(ProFeature.batchManagement), isTrue);
    });
  }

  for (final state in [
    SubscriptionState.free,
    SubscriptionState.expired,
    SubscriptionState.revoked,
  ]) {
    test('$state uses Free limits', () {
      final access = EntitlementProFeatureAccess(
        MockSubscriptionRepository(
          current: SubscriptionEntitlement(state: state),
        ),
      );
      expect(access.activeCredentialLimit, 3);
      expect(access.canUse(ProFeature.unlimitedActiveCredentials), isFalse);
      expect(access.canUse(ProFeature.batchManagement), isFalse);
    });
  }
}
