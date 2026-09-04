import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/account/account_pages.dart';
import 'package:packagehub/subscription/debug/debug_subscription_override.dart';
import 'package:packagehub/subscription/debug_entitlement_override_policy.dart';
import 'package:packagehub/subscription/entitlement_pro_feature_access.dart';
import 'package:packagehub/subscription/pro_feature.dart';
import 'package:packagehub/subscription/storekit_models.dart';
import 'package:packagehub/subscription/subscription_entitlement.dart';
import 'package:packagehub/subscription/subscription_repository.dart';
import 'package:packagehub/subscription/subscription_state.dart';

class _MutableRepository extends SubscriptionRepository {
  SubscriptionEntitlement value;
  final _changes = StreamController<SubscriptionEntitlement>.broadcast();

  _MutableRepository(this.value);

  @override
  SubscriptionEntitlement get current => value;
  @override
  Stream<SubscriptionEntitlement> get changes => _changes.stream;

  void update(SubscriptionEntitlement next) {
    value = next;
    _changes.add(next);
  }

  @override
  Future<StoreProduct?> loadProProduct() async => null;

  Future<void> dispose() => _changes.close();
}

void main() {
  test('debug builds allow the entitlement override by default', () {
    expect(devEntitlementOverrideAllowed, isTrue);
  });

  testWidgets('debug entitlement segments respond to real taps and jitter', (
    tester,
  ) async {
    final backend = _MutableRepository(
      const SubscriptionEntitlement(state: SubscriptionState.free),
    );
    final controller = DebugSubscriptionOverrideController();
    final repository = ResolvedSubscriptionRepository(
      backendSubscriptionRepository: backend,
      debugOverrideController: controller,
    );
    addTearDown(() async {
      await repository.dispose();
      await controller.dispose();
      await backend.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(home: SubscriptionPage(subscriptionRepository: repository)),
    );
    final control = find.byKey(const Key('debugEntitlementSegmentedControl'));
    await tester.scrollUntilVisible(control, 300);
    await tester.pump();
    expect(find.text('真实'), findsOneWidget);

    await tester.tap(find.text('Free'));
    await tester.pumpAndSettle();
    expect(repository.mode, DebugEntitlementMode.free);
    expect(repository.current.isPro, isFalse);

    await tester.tap(find.text('Pro'));
    await tester.pumpAndSettle();
    expect(repository.mode, DebugEntitlementMode.pro);
    await tester.drag(find.byType(ListView), const Offset(0, 500));
    await tester.pump();
    expect(find.text('PackageHub Pro（开发）'), findsOneWidget);

    await tester.scrollUntilVisible(control, 300);
    await tester.tap(find.text('真实'));
    await tester.pumpAndSettle();
    expect(repository.mode, DebugEntitlementMode.automatic);

    await tester.tap(find.text('Pro'));
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Pro')),
    );
    await gesture.moveBy(const Offset(2, 1));
    await gesture.up();
    await tester.pump();
    expect(repository.mode, DebugEntitlementMode.pro);
  });

  test(
    'one resolved repository updates ProFeatureAccess immediately',
    () async {
      final backend = _MutableRepository(
        const SubscriptionEntitlement(state: SubscriptionState.free),
      );
      final controller = DebugSubscriptionOverrideController();
      final repository = ResolvedSubscriptionRepository(
        backendSubscriptionRepository: backend,
        debugOverrideController: controller,
      );
      final access = EntitlementProFeatureAccess(repository);
      addTearDown(() async {
        await repository.dispose();
        await controller.dispose();
        await backend.dispose();
      });

      expect(access.activeCredentialLimit, 3);
      expect(access.canUse(ProFeature.batchManagement), isFalse);
      controller.setOverride(DebugEntitlementMode.pro);
      expect(access.activeCredentialLimit, isNull);
      expect(access.canUse(ProFeature.batchManagement), isTrue);
      controller.setOverride(DebugEntitlementMode.free);
      expect(access.activeCredentialLimit, 3);
      expect(access.canUse(ProFeature.batchManagement), isFalse);
      controller.setOverride(DebugEntitlementMode.automatic);
      expect(repository.current.isPro, isFalse);
    },
  );

  test('automatic mode follows backend changes', () async {
    final backend = _MutableRepository(
      const SubscriptionEntitlement(state: SubscriptionState.free),
    );
    final controller = DebugSubscriptionOverrideController();
    final repository = ResolvedSubscriptionRepository(
      backendSubscriptionRepository: backend,
      debugOverrideController: controller,
    );
    final emitted = <SubscriptionEntitlement>[];
    final subscription = repository.changes.listen(emitted.add);
    addTearDown(() async {
      await subscription.cancel();
      await repository.dispose();
      await controller.dispose();
      await backend.dispose();
    });

    backend.update(
      const SubscriptionEntitlement(state: SubscriptionState.active),
    );
    await Future<void>.delayed(Duration.zero);
    expect(repository.current.isPro, isTrue);
    expect(emitted.last.isPro, isTrue);
  });
}
