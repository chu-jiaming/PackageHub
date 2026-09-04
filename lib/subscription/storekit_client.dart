import 'dart:async';

import 'package:flutter/services.dart';

import 'storekit_models.dart';

abstract class StoreKitClient {
  Future<List<StoreProduct>> loadProducts(List<String> productIds);
  Future<StorePurchaseResult> purchase({
    required String productId,
    required String appAccountToken,
  });
  Future<StoreSubscriptionSnapshot> loadSubscriptionSnapshot(
    List<String> productIds,
  );
  Future<void> restorePurchases();
  Stream<StoreKitEvent> get events;
}

class MethodChannelStoreKitClient implements StoreKitClient {
  static const _method = MethodChannel('packagehub/storekit');
  static const _event = EventChannel('packagehub/storekit_events');

  @override
  Stream<StoreKitEvent> get events => _event.receiveBroadcastStream().map(
    (value) => StoreKitEvent((value as Map)['type'] as String? ?? 'updated'),
  );

  @override
  Future<List<StoreProduct>> loadProducts(List<String> productIds) async {
    final result = await _method.invokeMethod<List<Object?>>('loadProducts', {
      'productIds': productIds,
    });
    return (result ?? const [])
        .whereType<Map>()
        .map((item) => StoreProduct.fromMap(Map<Object?, Object?>.from(item)))
        .toList();
  }

  @override
  Future<StorePurchaseResult> purchase({
    required String productId,
    required String appAccountToken,
  }) async {
    try {
      final result = await _method.invokeMethod<Map<Object?, Object?>>(
        'purchase',
        {'productId': productId, 'appAccountToken': appAccountToken},
      );
      final status = result?['status'] as String?;
      return switch (status) {
        'purchased' => StorePurchaseResult.success(StorePurchaseStatus.purchased, signedTransaction: result?['signedTransaction'] as String?),
        'pending' => const StorePurchaseResult.success(
          StorePurchaseStatus.pending,
        ),
        'userCancelled' => const StorePurchaseResult.success(
          StorePurchaseStatus.userCancelled,
        ),
        'productUnavailable' => const StorePurchaseResult.failure(
          StorePurchaseError.productUnavailable,
        ),
        'networkUnavailable' => const StorePurchaseResult.failure(
          StorePurchaseError.networkUnavailable,
        ),
        'verificationFailed' => const StorePurchaseResult.failure(
          StorePurchaseError.verificationFailed,
        ),
        'unboundPurchase' => const StorePurchaseResult.failure(
          StorePurchaseError.unboundPurchase,
        ),
        'accountTokenMismatch' => const StorePurchaseResult.failure(
          StorePurchaseError.accountTokenMismatch,
        ),
        _ => const StorePurchaseResult.failure(StorePurchaseError.unknown),
      };
    } on PlatformException catch (error) {
      return StorePurchaseResult.failure(switch (error.code) {
        'PRODUCT_UNAVAILABLE' => StorePurchaseError.productUnavailable,
        'NETWORK_UNAVAILABLE' => StorePurchaseError.networkUnavailable,
        'STOREKIT_UNAVAILABLE' => StorePurchaseError.storeKitUnavailable,
        _ => StorePurchaseError.unknown,
      });
    } on MissingPluginException {
      return const StorePurchaseResult.failure(
        StorePurchaseError.storeKitUnavailable,
      );
    }
  }

  @override
  Future<StoreSubscriptionSnapshot> loadSubscriptionSnapshot(
    List<String> productIds,
  ) async {
    final result = await _method.invokeMethod<List<Object?>>(
      'currentEntitlements',
      {'productIds': productIds},
    );
    return StoreSubscriptionSnapshot(
      (result ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                StoreKitEntitlement.fromMap(Map<Object?, Object?>.from(item)),
          )
          .toList(),
    );
  }

  @override
  Future<void> restorePurchases() async {
    try {
      await _method.invokeMethod('restorePurchases');
    } on MissingPluginException {
      // Non-iOS platforms have no StoreKit implementation.
    }
  }

  Future<void> finishTransaction(String transactionId) async {
    await _method.invokeMethod('finishTransaction', {'transactionId': transactionId});
  }
}
