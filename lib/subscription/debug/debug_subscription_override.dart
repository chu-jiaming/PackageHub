import 'dart:async';

import 'package:flutter/foundation.dart';

import '../debug_entitlement_override_policy.dart';
import '../storekit_models.dart';
import '../subscription_entitlement.dart';
import '../subscription_repository.dart';
import '../subscription_state.dart';

enum DebugEntitlementMode {
  automatic,
  @Deprecated('Use automatic')
  storeKit,
  free,
  pro,
}

/// Process-local only; this never persists or calls StoreKit/backend.
class DebugSubscriptionOverrideController {
  DebugEntitlementMode _mode = DebugEntitlementMode.automatic;
  final _changes = StreamController<DebugEntitlementMode>.broadcast();

  DebugEntitlementMode get mode => _mode;
  Stream<DebugEntitlementMode> get changes => _changes.stream;

  void setOverride(DebugEntitlementMode mode) {
    if (mode == DebugEntitlementMode.storeKit) {
      mode = DebugEntitlementMode.automatic;
    }
    if (!devEntitlementOverrideAllowed || mode == _mode) return;
    final previous = _mode;
    _mode = mode;
    debugPrint('Debug entitlement override: ${previous.name} → ${mode.name}');
    _changes.add(mode);
  }

  Future<void> dispose() => _changes.close();
}

/// The sole effective entitlement repository consumed by app features.
class ResolvedSubscriptionRepository implements SubscriptionRepository {
  final SubscriptionRepository backendSubscriptionRepository;
  final DebugSubscriptionOverrideController debugOverrideController;
  final _changes = StreamController<SubscriptionEntitlement>.broadcast();
  late final StreamSubscription<SubscriptionEntitlement> _backendChanges;
  late final StreamSubscription<DebugEntitlementMode> _overrideChanges;
  SubscriptionEntitlement? _lastEmitted;

  ResolvedSubscriptionRepository({
    required this.backendSubscriptionRepository,
    required this.debugOverrideController,
  }) {
    _backendChanges = backendSubscriptionRepository.changes.listen(
      (_) => _emit(),
    );
    _overrideChanges = debugOverrideController.changes.listen((_) => _emit());
  }

  DebugEntitlementMode get mode => debugOverrideController.mode;

  @override
  SubscriptionEntitlement get current => _resolve();

  SubscriptionEntitlement _resolve() {
    if (!devEntitlementOverrideAllowed ||
        mode == DebugEntitlementMode.automatic ||
        mode == DebugEntitlementMode.storeKit) {
      return backendSubscriptionRepository.current;
    }
    if (mode == DebugEntitlementMode.free) {
      return const SubscriptionEntitlement(state: SubscriptionState.free);
    }
    return const SubscriptionEntitlement(
      state: SubscriptionState.active,
      productId: 'debug.packagehub.pro',
      planDisplayName: 'PackageHub Pro（开发）',
    );
  }

  void _emit() {
    final value = _resolve();
    if (_same(_lastEmitted, value)) return;
    _lastEmitted = value;
    if (kDebugMode) debugPrint('Resolved entitlement: ${mode.name}');
    _changes.add(value);
  }

  bool _same(SubscriptionEntitlement? a, SubscriptionEntitlement b) =>
      a?.state == b.state &&
      a?.productId == b.productId &&
      a?.planDisplayName == b.planDisplayName &&
      a?.expiresAt == b.expiresAt &&
      a?.autoRenewEnabled == b.autoRenewEnabled;

  @override
  Stream<SubscriptionEntitlement> get changes async* {
    yield current;
    yield* _changes.stream;
  }

  @override
  Future<void> refresh() => backendSubscriptionRepository.refresh();
  @override
  Future<StoreProduct?> loadProProduct() =>
      backendSubscriptionRepository.loadProProduct();
  @override
  Future<StorePurchaseResult> purchasePro() =>
      backendSubscriptionRepository.purchasePro();
  @override
  Future<void> restorePurchases() =>
      backendSubscriptionRepository.restorePurchases();

  Future<void> dispose() async {
    await _backendChanges.cancel();
    await _overrideChanges.cancel();
    await _changes.close();
  }
}

/// Source-compatible adapter for existing callers; app composition uses the
/// controller and resolved repository directly so there is one shared pair.
class DebugSubscriptionOverrideRepository
    extends ResolvedSubscriptionRepository {
  factory DebugSubscriptionOverrideRepository(SubscriptionRepository base) {
    final controller = DebugSubscriptionOverrideController();
    return DebugSubscriptionOverrideRepository._(base, controller);
  }

  DebugSubscriptionOverrideRepository._(
    SubscriptionRepository base,
    this.controller,
  ) : super(
        backendSubscriptionRepository: base,
        debugOverrideController: controller,
      );

  final DebugSubscriptionOverrideController controller;

  void setMode(DebugEntitlementMode mode) => controller.setOverride(mode);
}
