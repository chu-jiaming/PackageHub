import 'dart:async';

import 'package:packagehub/account/account_repository.dart';

import 'storekit_client.dart';
import 'storekit_models.dart';
import 'storekit_product_ids.dart';
import 'subscription_entitlement.dart';
import 'subscription_repository.dart';
import 'subscription_state.dart';

class StoreKitSubscriptionRepository implements SubscriptionRepository {
  final StoreKitClient client;
  final AccountRepository accountRepository;
  SubscriptionEntitlement _current = const SubscriptionEntitlement(
    state: SubscriptionState.free,
  );
  final _changes = StreamController<SubscriptionEntitlement>.broadcast();
  StoreProduct? _product;
  StreamSubscription<StoreKitEvent>? _updates;
  StreamSubscription<dynamic>? _accountUpdates;

  StoreKitSubscriptionRepository({
    required this.client,
    required this.accountRepository,
  }) {
    _updates = client.events.listen((_) => refresh());
    _accountUpdates = accountRepository.changes.listen((_) => refresh());
  }

  @override
  SubscriptionEntitlement get current => _current;
  @override
  Stream<SubscriptionEntitlement> get changes => _changes.stream;

  @override
  Future<void> refresh() async {
    if (!accountRepository.current.isSignedIn) return _set(_free);
    try {
      final token = await accountRepository.storeKitAppAccountToken();
      if (token == null) return _set(_free);
      final snapshot = await client.loadSubscriptionSnapshot([
        StoreKitProductIds.pro,
      ]);
      final match = snapshot.entitlements
          .where(
            (e) =>
                e.productId == StoreKitProductIds.pro &&
                e.appAccountToken == token,
          )
          .firstOrNull;
      if (match == null) return _set(_free);
      _set(
        SubscriptionEntitlement(
          state: match.state,
          productId: match.productId,
          planDisplayName: _product?.displayName ?? 'PackageHub Pro',
          expiresAt: match.expiresAt,
          autoRenewEnabled: match.autoRenewEnabled,
        ),
      );
    } catch (_) {
      _set(_free);
    }
  }

  SubscriptionEntitlement get _free =>
      const SubscriptionEntitlement(state: SubscriptionState.free);
  void _set(SubscriptionEntitlement value) {
    if (value.state == _current.state &&
        value.productId == _current.productId &&
        value.expiresAt == _current.expiresAt) {
      return;
    }
    _current = value;
    _changes.add(value);
  }

  @override
  Future<StoreProduct?> loadProProduct() async {
    try {
      final products = await client.loadProducts([StoreKitProductIds.pro]);
      _product = products
          .where((p) => p.id == StoreKitProductIds.pro)
          .firstOrNull;
      return _product;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<StorePurchaseResult> purchasePro() async {
    if (!accountRepository.current.isSignedIn) {
      return const StorePurchaseResult.failure(
        StorePurchaseError.accountRequired,
      );
    }
    final token = await accountRepository.storeKitAppAccountToken();
    if (token == null) {
      return const StorePurchaseResult.failure(
        StorePurchaseError.accountRequired,
      );
    }
    final result = await client.purchase(
      productId: StoreKitProductIds.pro,
      appAccountToken: token,
    );
    if (result.status == StorePurchaseStatus.purchased) await refresh();
    return result;
  }

  @override
  Future<void> restorePurchases() async {
    await client.restorePurchases();
    await refresh();
  }

  Future<void> dispose() async {
    await _updates?.cancel();
    await _accountUpdates?.cancel();
    await _changes.close();
  }
}
