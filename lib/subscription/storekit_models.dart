import 'subscription_state.dart';

class StoreProduct {
  final String id;
  final String displayName;
  final String description;
  final String displayPrice;
  final String? subscriptionPeriodDisplay;
  final String? introductoryOfferDisplay;

  const StoreProduct({
    required this.id,
    required this.displayName,
    required this.description,
    required this.displayPrice,
    this.subscriptionPeriodDisplay,
    this.introductoryOfferDisplay,
  });

  factory StoreProduct.fromMap(Map<Object?, Object?> map) => StoreProduct(
    id: map['id'] as String,
    displayName: map['displayName'] as String? ?? '',
    description: map['description'] as String? ?? '',
    displayPrice: map['displayPrice'] as String? ?? '',
    subscriptionPeriodDisplay: map['subscriptionPeriodDisplay'] as String?,
    introductoryOfferDisplay: map['introductoryOfferDisplay'] as String?,
  );
}

enum StorePurchaseStatus { purchased, pending, userCancelled }

enum StorePurchaseError {
  productUnavailable,
  networkUnavailable,
  verificationFailed,
  accountRequired,
  accountTokenMismatch,
  unboundPurchase,
  storeKitUnavailable,
  unknown,
}

class StorePurchaseResult {
  final StorePurchaseStatus? status;
  final StorePurchaseError? error;
  final String? signedTransaction;
  const StorePurchaseResult.success(this.status, {this.signedTransaction}) : error = null;
  const StorePurchaseResult.failure(this.error) : status = null, signedTransaction = null;
}

class StoreKitEvent {
  final String type;
  const StoreKitEvent(this.type);
}

class StoreKitEntitlement {
  final String productId;
  final String? appAccountToken;
  final SubscriptionState state;
  final DateTime? expiresAt;
  final bool autoRenewEnabled;
  final String? signedTransaction;

  const StoreKitEntitlement({
    required this.productId,
    required this.state,
    this.appAccountToken,
    this.expiresAt,
    this.autoRenewEnabled = false,
    this.signedTransaction,
  });

  factory StoreKitEntitlement.fromMap(Map<Object?, Object?> map) =>
      StoreKitEntitlement(
        productId: map['productId'] as String,
        appAccountToken: map['appAccountToken'] as String?,
        state: _state(map['state'] as String?),
        expiresAt: map['expiresAt'] is String
            ? DateTime.tryParse(map['expiresAt'] as String)
            : null,
        autoRenewEnabled: map['autoRenewEnabled'] as bool? ?? false,
        signedTransaction: map['signedTransaction'] as String?,
      );

  static SubscriptionState _state(String? value) => switch (value) {
    'trial' => SubscriptionState.trial,
    'gracePeriod' => SubscriptionState.gracePeriod,
    'billingRetry' => SubscriptionState.billingRetry,
    'expired' => SubscriptionState.expired,
    'revoked' => SubscriptionState.revoked,
    _ => SubscriptionState.active,
  };
}

class StoreSubscriptionSnapshot {
  final List<StoreKitEntitlement> entitlements;
  const StoreSubscriptionSnapshot(this.entitlements);
}
