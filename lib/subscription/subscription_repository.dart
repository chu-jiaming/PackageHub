import 'subscription_entitlement.dart';
import 'storekit_models.dart';

abstract class SubscriptionRepository {
  const SubscriptionRepository();
  SubscriptionEntitlement get current;
  Stream<SubscriptionEntitlement> get changes => Stream.value(current);
  Future<void> refresh() async {}
  Future<StoreProduct?> loadProProduct() async => null;
  Future<StorePurchaseResult> purchasePro() async =>
      const StorePurchaseResult.failure(StorePurchaseError.storeKitUnavailable);
  Future<void> restorePurchases() async {}
}
