import 'subscription_entitlement.dart';

/// Future boundary: replace the mock with the real subscription integration.
abstract class SubscriptionRepository {
  SubscriptionEntitlement get current;
}
