import 'dart:async';

import 'account_device.dart';

import 'package:crypto/crypto.dart';

import 'dart:convert';

import 'account_api_client.dart';
import 'account_repository.dart';
import 'account_state.dart';
import 'apple_sign_in_client.dart';
import 'installation_id_store.dart';
import 'secure_token_store.dart';

class RealAccountRepository implements AccountRepository {
  final AccountApiClient? api;
  final AppleSignInClient apple;
  final SecureTokenStore tokens;
  final InstallationIdStore installation;
  AccountState _state = const AccountState.signedOut();
  final _changes = StreamController<AccountState>.broadcast();
  String? _access;
  RealAccountRepository({
    required this.api,
    AppleSignInClient? apple,
    SecureTokenStore? tokens,
    InstallationIdStore? installation,
  }) : apple = apple ?? MethodChannelAppleSignInClient(),
       tokens = tokens ?? FlutterSecureTokenStore(),
       installation = installation ?? const InstallationIdStore();
  @override
  AccountState get current => _state;
  @override
  Stream<AccountState> get changes => _changes.stream;
  void _set(AccountState s) {
    _state = s;
    _changes.add(s);
  }

  @override
  Future<void> restoreSession() async {
    if (api == null) {
      _set(const AccountState.signedOut());
      return;
    }
    _set(const AccountState.restoring());
    final t = await tokens.readRefreshToken();
    if (t == null) {
      _set(const AccountState.signedOut());
      return;
    }
    try {
      final s = await api!.refresh(t);
      await tokens.saveRefreshToken(s.refreshToken);
      _access = s.accessToken;
      _set(AccountState.signedIn(s.user));
    } catch (e) {
      if (e is AccountApiException && e.status == 401) {
        await tokens.clearRefreshToken();
      }
      _set(const AccountState.signedOut());
    }
  }

  @override
  Future<void> signInWithApple() async {
    final a = api;
    if (a == null) throw StateError('configurationMissing');
    final i = await installation.getOrCreate();
    final c = await a.challenge(i);
    final hashed = sha256.convert(utf8.encode(c.nonce)).toString();
    final cred = await apple.authorize(nonce: hashed, state: c.state);
    if (cred.state != c.state) throw StateError('serverRejected');
    final s = await a.apple(
      challenge: c,
      identityToken: cred.identityToken,
      authorizationCode: cred.authorizationCode,
      returnedState: cred.state,
      installationId: i,
      email: cred.email,
      displayName: [
        cred.givenName,
        cred.familyName,
      ].whereType<String>().join(' ').trim(),
    );
    await tokens.saveRefreshToken(s.refreshToken);
    _access = s.accessToken;
    _set(AccountState.signedIn(s.user));
  }

  @override
  Future<void> signOut() async {
    final a = _access;
    if (a != null && api != null) await api!.logout(a).catchError((_) {});
    _access = null;
    await tokens.clearRefreshToken();
    _set(const AccountState.signedOut());
  }

  @override
  Future<void> deleteAccount() async {
    final a = _access;
    if (a == null || api == null) throw StateError('notSignedIn');
    await api!.delete(a);
    _access = null;
    await tokens.clearRefreshToken();
    _set(const AccountState.signedOut());
  }

  @override
  Future<List<AccountDevice>> loadDevices() async {
    if (api == null || _access == null) return [];
    return api!.devices(_access!);
  }
}
