import 'dart:async';

import 'package:flutter/foundation.dart';

import '../storekit_models.dart';
import '../subscription_entitlement.dart';
import '../subscription_repository.dart';
import '../subscription_state.dart';

enum DebugEntitlementMode { storeKit, free, pro }

class DebugSubscriptionOverrideRepository implements SubscriptionRepository {
  final SubscriptionRepository base;
  DebugEntitlementMode _mode = DebugEntitlementMode.storeKit;
  final _changes = StreamController<SubscriptionEntitlement>.broadcast();
  DebugSubscriptionOverrideRepository(this.base);

  DebugEntitlementMode get mode => _mode;
  @override
  SubscriptionEntitlement get current {
    if (!kDebugMode || _mode == DebugEntitlementMode.storeKit) {
      return base.current;
    }
    if (_mode == DebugEntitlementMode.free) {
      return const SubscriptionEntitlement(state: SubscriptionState.free);
    }
    return const SubscriptionEntitlement(
      state: SubscriptionState.active,
      productId: 'debug.packagehub.pro',
      planDisplayName: 'PackageHub Pro（开发）',
    );
  }

  void setMode(DebugEntitlementMode mode) {
    if (!kDebugMode) return;
    _mode = mode;
    _changes.add(current);
  }

  @override
  Stream<SubscriptionEntitlement> get changes async* {
    yield current;
    yield* _changes.stream;
  }

  @override
  Future<void> refresh() => base.refresh();
  @override
  Future<StoreProduct?> loadProProduct() => base.loadProProduct();
  @override
  Future<StorePurchaseResult> purchasePro() => base.purchasePro();
  @override
  Future<void> restorePurchases() => base.restorePurchases();
}
