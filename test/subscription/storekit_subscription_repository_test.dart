import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/account/account_repository.dart';
import 'package:packagehub/account/account_state.dart';
import 'package:packagehub/account/account_user.dart';
import 'package:packagehub/subscription/debug/debug_subscription_override.dart';
import 'package:packagehub/subscription/storekit_client.dart';
import 'package:packagehub/subscription/storekit_models.dart';
import 'package:packagehub/subscription/storekit_product_ids.dart';
import 'package:packagehub/subscription/storekit_subscription_repository.dart';
import 'package:packagehub/subscription/subscription_state.dart';

class _Account extends AccountRepository {
  @override
  AccountState get current => const AccountState.signedIn(
    AccountUser(id: 'u', displayName: null, email: null),
  );
  @override
  Future<String?> storeKitAppAccountToken() async =>
      '11111111-1111-1111-1111-111111111111';
}

class _Store extends StoreKitClient {
  final List<StoreKitEntitlement> values;
  _Store(this.values);
  @override
  Stream<StoreKitEvent> get events => const Stream.empty();
  @override
  Future<List<StoreProduct>> loadProducts(List<String> ids) async => const [
    StoreProduct(
      id: StoreKitProductIds.pro,
      displayName: 'PackageHub Pro',
      description: 'Pro',
      displayPrice: '¥1',
    ),
  ];
  @override
  Future<StorePurchaseResult> purchase({
    required String productId,
    required String appAccountToken,
  }) async => const StorePurchaseResult.success(StorePurchaseStatus.purchased);
  @override
  Future<StoreSubscriptionSnapshot> loadSubscriptionSnapshot(
    List<String> ids,
  ) async => StoreSubscriptionSnapshot(values);
  @override
  Future<void> restorePurchases() async {}
}

void main() {
  test('verified matching entitlement grants Pro', () async {
    final repository = StoreKitSubscriptionRepository(
      client: _Store([
        const StoreKitEntitlement(
          productId: StoreKitProductIds.pro,
          state: SubscriptionState.active,
          appAccountToken: '11111111-1111-1111-1111-111111111111',
        ),
      ]),
      accountRepository: _Account(),
    );
    await repository.refresh();
    expect(repository.current.isPro, isTrue);
    await repository.dispose();
  });

  test('wrong token and other product do not grant Pro', () async {
    for (final entitlement in [
      const StoreKitEntitlement(
        productId: StoreKitProductIds.pro,
        state: SubscriptionState.active,
        appAccountToken: '22222222-2222-2222-2222-222222222222',
      ),
      const StoreKitEntitlement(
        productId: 'other',
        state: SubscriptionState.active,
        appAccountToken: '11111111-1111-1111-1111-111111111111',
      ),
    ]) {
      final repository = StoreKitSubscriptionRepository(
        client: _Store([entitlement]),
        accountRepository: _Account(),
      );
      await repository.refresh();
      expect(repository.current.isPro, isFalse);
      await repository.dispose();
    }
  });

  test('debug override switches entitlement immediately', () async {
    final base = StoreKitSubscriptionRepository(
      client: _Store(const []),
      accountRepository: _Account(),
    );
    final override = DebugSubscriptionOverrideRepository(base);
    override.setMode(DebugEntitlementMode.pro);
    expect(override.current.isPro, isTrue);
    override.setMode(DebugEntitlementMode.free);
    expect(override.current.isPro, isFalse);
    await base.dispose();
  });
}
