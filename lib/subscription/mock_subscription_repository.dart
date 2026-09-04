import 'subscription_entitlement.dart';
import 'subscription_repository.dart';
import 'subscription_state.dart';

class MockSubscriptionRepository extends SubscriptionRepository {
  @override
  final SubscriptionEntitlement current;

  const MockSubscriptionRepository({
    this.current = const SubscriptionEntitlement(state: SubscriptionState.free),
  });
}
