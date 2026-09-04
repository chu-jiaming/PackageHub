import AuthenticationServices
import Flutter

final class AppleSignInService: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
  private var result: FlutterResult?
  func authorize(arguments: [String: Any], result: @escaping FlutterResult) {
    guard let nonce = arguments["nonce"] as? String, let state = arguments["state"] as? String else { result(FlutterError(code: "INVALID_ARGUMENTS", message: "nonce/state required", details: nil)); return }
    self.result = result
    let request = ASAuthorizationAppleIDProvider().createRequest(); request.requestedScopes = [.fullName, .email]; request.nonce = nonce; request.state = state
    let controller = ASAuthorizationController(authorizationRequests: [request]); controller.delegate = self; controller.presentationContextProvider = self; controller.performRequests()
  }
  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential, let identity = credential.identityToken, let code = credential.authorizationCode, let identityToken = String(data: identity, encoding: .utf8), let authorizationCode = String(data: code, encoding: .utf8) else { result?(FlutterError(code: "INVALID_CREDENTIAL", message: "Apple credential unavailable", details: nil)); result = nil; return }
    result?(["userIdentifier": credential.user, "identityToken": identityToken, "authorizationCode": authorizationCode, "email": credential.email, "givenName": credential.fullName?.givenName, "familyName": credential.fullName?.familyName, "state": credential.state]); result = nil
  }
  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) { let ns = error as NSError; result?(FlutterError(code: ns.code == ASAuthorizationError.canceled.rawValue ? "CANCELLED" : "APPLE_ERROR", message: nil, details: nil)); result = nil }
  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor { UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }.first { $0.isKeyWindow } ?? UIWindow() }
}
