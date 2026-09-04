import 'package:flutter/services.dart';

class AppleSignInCancelled implements Exception {}

class AppleSignInCredential {
  final String userIdentifier, identityToken, authorizationCode, state;
  final String? email, givenName, familyName;
  const AppleSignInCredential({
    required this.userIdentifier,
    required this.identityToken,
    required this.authorizationCode,
    required this.state,
    this.email,
    this.givenName,
    this.familyName,
  });
}

abstract class AppleSignInClient {
  Future<AppleSignInCredential> authorize({
    required String nonce,
    required String state,
  });
}

class MethodChannelAppleSignInClient implements AppleSignInClient {
  static const _channel = MethodChannel('packagehub/apple_sign_in');
  @override
  Future<AppleSignInCredential> authorize({
    required String nonce,
    required String state,
  }) async {
    try {
      final value = await _channel.invokeMethod<Map<Object?, Object?>>(
        'authorize',
        {'nonce': nonce, 'state': state},
      );
      final m = Map<String, Object?>.from(value ?? {});
      return AppleSignInCredential(
        userIdentifier: m['userIdentifier']! as String,
        identityToken: m['identityToken']! as String,
        authorizationCode: m['authorizationCode']! as String,
        state: m['state']! as String,
        email: m['email'] as String?,
        givenName: m['givenName'] as String?,
        familyName: m['familyName'] as String?,
      );
    } on PlatformException catch (e) {
      if (e.code == 'CANCELLED') throw AppleSignInCancelled();
      rethrow;
    }
  }
}
