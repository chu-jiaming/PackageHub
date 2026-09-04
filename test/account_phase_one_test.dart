import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/account/account_state.dart';
import 'package:packagehub/account/account_user.dart';
import 'package:packagehub/account/mock_account_repository.dart';
import 'package:packagehub/core/repository/pickup_credential_repository.dart';
import 'package:packagehub/main.dart';
import 'package:packagehub/models/pickup_credential.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';
import 'package:packagehub/subscription/mock_subscription_repository.dart';
import 'package:packagehub/subscription/subscription_entitlement.dart';
import 'package:packagehub/subscription/subscription_state.dart';

void main() {
  test('entitlement exposes centralized Pro semantics', () {
    expect(
      const SubscriptionEntitlement(state: SubscriptionState.active).isPro,
      isTrue,
    );
    expect(
      const SubscriptionEntitlement(state: SubscriptionState.gracePeriod).isPro,
      isTrue,
    );
    expect(
      const SubscriptionEntitlement(state: SubscriptionState.expired).isPro,
      isFalse,
    );
  });

  testWidgets(
    'home avatar opens signed-out account hub and overlay dismisses',
    (tester) async {
      await tester.pumpWidget(PackageHubApp(repository: _EmptyRepo()));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('账户'), findsOneWidget);
      await tester.tap(find.byKey(const Key('accountAvatarButton')));
      await tester.pumpAndSettle();
      expect(find.text('未登录'), findsOneWidget);
      expect(find.text('PackageHub Free'), findsOneWidget);
      expect(find.text('账号信息'), findsOneWidget);
      expect(find.text('关于 PackageHub'), findsOneWidget);
      await tester.tap(find.byKey(const Key('accountHubDimOverlay')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('accountHubDimOverlay')), findsNothing);
    },
  );

  testWidgets('injected signed-in Pro state is shown consistently', (
    tester,
  ) async {
    await tester.pumpWidget(
      PackageHubApp(
        repository: _EmptyRepo(),
        accountRepository: const MockAccountRepository(
          current: AccountState.signedIn(
            AccountUser(
              id: 'id',
              displayName: 'Example User',
              email: 'example@privaterelay.appleid.com',
            ),
          ),
        ),
        subscriptionRepository: MockSubscriptionRepository(
          current: SubscriptionEntitlement(
            state: SubscriptionState.active,
            planDisplayName: '年度方案',
            expiresAt: DateTime(2027, 9, 4),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('accountAvatarButton')));
    await tester.pumpAndSettle();
    expect(find.text('Example User'), findsOneWidget);
    expect(find.text('PackageHub Pro'), findsOneWidget);
    expect(find.text('年度方案'), findsOneWidget);
    await tester.tap(find.text('订阅与权益').last);
    await tester.pumpAndSettle();
    expect(find.text('订阅与权益'), findsOneWidget);
    expect(find.text('有效至 2027/09/04'), findsOneWidget);
  });
}

class _EmptyRepo implements PickupCredentialRepositoryApi {
  @override
  Future<List<PickupCredential>> getAll() async => [];
  @override
  Future<List<PickupCredential>> getPending() async => [];
  @override
  Future<List<PickupCredential>> getPickedUp() async => [];
  @override
  Future<List<PickupCredential>> findByTrackingNumber(String value) async => [];
  @override
  Future<List<PickupCredential>> insertAll(
    List<PickupCredentialDraft> drafts,
  ) async => [];
  @override
  Future<PickupCredential> update(PickupCredential credential) =>
      throw UnimplementedError();
  @override
  Future<PickupCredential> markPickedUp(int id) => throw UnimplementedError();
  @override
  Future<PickupCredential> markPending(int id) => throw UnimplementedError();
  @override
  Future<void> deleteById(int id) async {}
  @override
  Future<List<PickupCredential>> markPickedUpAll(Iterable<int> ids) async => [];
  @override
  Future<List<PickupCredential>> markPendingAll(Iterable<int> ids) async => [];
  @override
  Future<void> deleteAll(Iterable<int> ids) async {}
}
