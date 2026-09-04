import Flutter
import StoreKit

@available(iOS 15.0, *)
final class StoreKitService: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var updatesTask: Task<Void, Never>?

  func attach(messenger: FlutterBinaryMessenger) {
    FlutterEventChannel(name: "packagehub/storekit_events", binaryMessenger: messenger)
      .setStreamHandler(self)
    updatesTask = Task { [weak self] in
      for await result in Transaction.updates {
        guard let self else { return }
        await self.handleUpdate(result)
      }
    }
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: nil, details: nil)); return
    }
    switch call.method {
    case "loadProducts":
      Task { result(await self.loadProducts(args["productIds"] as? [String] ?? [])) }
    case "purchase":
      guard let id = args["productId"] as? String, let token = args["appAccountToken"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: nil, details: nil)); return
      }
      Task { result(await self.purchase(id: id, token: token)) }
    case "currentEntitlements":
      Task { result(await self.currentEntitlements(ids: args["productIds"] as? [String] ?? [])) }
    case "restorePurchases":
      Task {
        do { try await AppStore.sync(); result(nil) }
        catch { result(FlutterError(code: "NETWORK_UNAVAILABLE", message: nil, details: nil)) }
      }
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func loadProducts(_ ids: [String]) async -> [[String: Any]] {
    do {
      return try await Product.products(for: ids).map { product in
        ["id": product.id, "displayName": product.displayName,
         "description": product.description, "displayPrice": product.displayPrice]
      }
    } catch { return [] }
  }

  private func purchase(id: String, token: String) async -> [String: String] {
    guard let uuid = UUID(uuidString: token) else { return ["status": "unknown"] }
    do {
      guard let product = try await Product.products(for: [id]).first else {
        return ["status": "productUnavailable"]
      }
      switch try await product.purchase(options: [.appAccountToken(uuid)]) {
      case .success(let verification):
        switch verification {
        case .verified(let transaction):
          guard transaction.appAccountToken == uuid else { return ["status": "accountTokenMismatch"] }
          await transaction.finish()
          return ["status": "purchased"]
        case .unverified: return ["status": "verificationFailed"]
        }
      case .pending: return ["status": "pending"]
      case .userCancelled: return ["status": "userCancelled"]
      @unknown default: return ["status": "unknown"]
      }
    } catch { return ["status": "networkUnavailable"] }
  }

  private func currentEntitlements(ids: [String]) async -> [[String: Any]] {
    var values: [[String: Any]] = []
    let products = (try? await Product.products(for: ids)) ?? []
    for await verification in Transaction.currentEntitlements {
      guard case .verified(let transaction) = verification, ids.contains(transaction.productID) else { continue }
      var state = transaction.revocationDate != nil ? "revoked" :
        ((transaction.expirationDate ?? .distantFuture) <= Date() ? "expired" : "active")
      var autoRenewEnabled = true
      if let product = products.first(where: { $0.id == transaction.productID }),
         let subscription = product.subscription,
         let statuses = try? await subscription.status,
         let status = statuses.first(where: {
           guard case .verified(let statusTransaction) = $0.transaction else { return false }
           return statusTransaction.id == transaction.id
         }) {
        state = status.state == Product.SubscriptionInfo.RenewalState.inGracePeriod ? "gracePeriod" :
          status.state == Product.SubscriptionInfo.RenewalState.inBillingRetryPeriod ? "billingRetry" :
          status.state == Product.SubscriptionInfo.RenewalState.revoked ? "revoked" :
          status.state == Product.SubscriptionInfo.RenewalState.expired ? "expired" : "active"
        if case .verified(let renewalInfo) = status.renewalInfo {
          autoRenewEnabled = renewalInfo.willAutoRenew
        }
      }
      values.append(["productId": transaction.productID,
                     "appAccountToken": transaction.appAccountToken?.uuidString as Any,
                     "state": state,
                     "expiresAt": transaction.expirationDate?.ISO8601Format() as Any,
                     "autoRenewEnabled": autoRenewEnabled])
    }
    return values
  }

  private func handleUpdate(_ result: VerificationResult<Transaction>) async {
    guard case .verified(let transaction) = result else { return }
    await transaction.finish()
    eventSink?( ["type": "transactionUpdated"] )
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? { eventSink = events; return nil }
  func onCancel(withArguments arguments: Any?) -> FlutterError? { eventSink = nil; return nil }
  deinit { updatesTask?.cancel() }
}
