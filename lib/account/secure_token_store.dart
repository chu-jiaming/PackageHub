import 'package:flutter/services.dart';

abstract class SecureTokenStore {
  Future<String?> readRefreshToken();
  Future<void> saveRefreshToken(String token);
  Future<void> clearRefreshToken();
}

class FlutterSecureTokenStore implements SecureTokenStore {
  static const _channel = MethodChannel('packagehub/keychain');
  @override
  Future<String?> readRefreshToken() => _channel.invokeMethod<String>('read', {
    'key': 'packagehub.refresh_token',
  });
  @override
  Future<void> saveRefreshToken(String token) => _channel.invokeMethod<void>(
    'write',
    {'key': 'packagehub.refresh_token', 'value': token},
  );
  @override
  Future<void> clearRefreshToken() => _channel.invokeMethod<void>('delete', {
    'key': 'packagehub.refresh_token',
  });
}
