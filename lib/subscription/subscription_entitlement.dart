import 'subscription_state.dart';

class SubscriptionEntitlement {
  final SubscriptionState state;
  final String? productId;
  final String? planDisplayName;
  final DateTime? expiresAt;
  final bool autoRenewEnabled;

  const SubscriptionEntitlement({
    required this.state,
    this.productId,
    this.planDisplayName,
    this.expiresAt,
    this.autoRenewEnabled = false,
  });

  bool get isPro => switch (state) {
    SubscriptionState.active ||
    SubscriptionState.trial ||
    SubscriptionState.gracePeriod ||
    SubscriptionState.billingRetry => true,
    SubscriptionState.free ||
    SubscriptionState.expired ||
    SubscriptionState.revoked => false,
  };
}
