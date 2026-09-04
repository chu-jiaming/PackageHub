import 'dart:convert';

import 'package:http/http.dart' as http;

import 'account_user.dart';
import 'account_device.dart';

class AppleChallenge {
  final String id, nonce, state;
  const AppleChallenge(this.id, this.nonce, this.state);
}

class AccountSession {
  final AccountUser user;
  final String accessToken, refreshToken;
  const AccountSession(this.user, this.accessToken, this.refreshToken);
}

class AccountApiException implements Exception {
  final int status;
  final String code;
  const AccountApiException(this.status, this.code);
}

class StoreKitContext {
  final String appAccountToken;
  const StoreKitContext(this.appAccountToken);
}

class BackendEntitlement {
  final String state;
  final String? deviceId;
  final bool isPro;
  final String? productId, planDisplayName, expiresAt, signedEntitlementToken;
  final bool autoRenewEnabled;
  final String deviceAccess;
  const BackendEntitlement({required this.state, required this.isPro, this.productId, this.planDisplayName, this.expiresAt, this.signedEntitlementToken, this.deviceId, this.autoRenewEnabled=false, this.deviceAccess='allowed'});
}

class AccountApiClient {
  final String baseUrl;
  final http.Client client;
  AccountApiClient(this.baseUrl, {http.Client? client})
    : client = client ?? http.Client();
  Uri _uri(String p) => Uri.parse('$baseUrl$p');
  Future<AppleChallenge> challenge(String installationId) async {
    final r = await client.post(
      _uri('/v1/auth/apple/challenge'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'installationId': installationId}),
    );
    if (r.statusCode >= 400) {
      throw AccountApiException(r.statusCode, 'challenge_failed');
    }
    final j = jsonDecode(r.body);
    return AppleChallenge(j['challengeId'], j['nonce'], j['state']);
  }

  Future<AccountSession> apple({
    required AppleChallenge challenge,
    required String identityToken,
    required String authorizationCode,
    required String returnedState,
    required String installationId,
    String? email,
    String? displayName,
  }) async {
    final r = await client.post(
      _uri('/v1/auth/apple'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'challengeId': challenge.id,
        'identityToken': identityToken,
        'authorizationCode': authorizationCode,
        'returnedState': returnedState,
        'installationId': installationId,
        'platform': 'ios',
        'displayName': displayName,
        'email': email,
      }),
    );
    return _session(r);
  }

  Future<AccountSession> refresh(String token) async {
    final r = await client.post(
      _uri('/v1/auth/refresh'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'refreshToken': token}),
    );
    return _session(r);
  }

  Future<void> logout(String accessToken) async {
    await client.post(
      _uri('/v1/auth/logout'),
      headers: {'authorization': 'Bearer $accessToken'},
    );
  }

  Future<void> delete(String accessToken) async {
    final r = await client.delete(
      _uri('/v1/me'),
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (r.statusCode >= 400) {
      throw AccountApiException(r.statusCode, 'delete_failed');
    }
  }

  Future<List<AccountDevice>> devices(String accessToken) async {
    final r = await client.get(
      _uri('/v1/me/devices'),
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (r.statusCode >= 400) throw Exception('devices_failed');
    final list = (jsonDecode(r.body)['devices'] as List);
    return list
        .map(
          (d) => AccountDevice(
            id: d['id'],
            installationId: d['installationId'],
            platform: d['platform'],
            deviceLabel: d['deviceLabel'],
            lastSeenAt: DateTime.parse(d['lastSeenAt']),
          ),
        )
        .toList();
  }

  Future<StoreKitContext> storeKitContext(String accessToken) async {
    final r = await client.get(
      _uri('/v1/me/storekit-context'),
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (r.statusCode >= 400) {
      throw AccountApiException(r.statusCode, 'storekit_context_failed');
    }
    return StoreKitContext((jsonDecode(r.body)['appAccountToken'] as String));
  }

  Future<String> confirmTransaction(String accessToken, String signedTransaction) async {
    final r=await client.post(_uri('/v1/me/subscription/transactions'),headers:{'authorization':'Bearer $accessToken','content-type':'application/json'},body:jsonEncode({'signedTransaction':signedTransaction}));
    if(r.statusCode>=400) throw AccountApiException(r.statusCode,(jsonDecode(r.body) as Map)['error']?.toString()??'subscription_failed');
    return (jsonDecode(r.body)['result'] as String?)??'accepted';
  }
  Future<BackendEntitlement> entitlement(String accessToken) async {
    final r=await client.get(_uri('/v1/me/entitlement'),headers:{'authorization':'Bearer $accessToken'});
    if(r.statusCode>=400) throw AccountApiException(r.statusCode,'entitlement_failed');
    final j=jsonDecode(r.body); return BackendEntitlement(state:j['state'],isPro:j['isPro']??false,productId:j['productId'],planDisplayName:j['planDisplayName'],expiresAt:j['expiresAt'],deviceId:j['deviceId'],signedEntitlementToken:j['signedEntitlementToken'],autoRenewEnabled:j['autoRenewEnabled']??false,deviceAccess:j['deviceAccess']??'allowed');
  }
  Future<void> removeDevice(String accessToken,String deviceId) async { final r=await client.delete(_uri('/v1/me/devices/$deviceId'),headers:{'authorization':'Bearer $accessToken'}); if(r.statusCode>=400) throw AccountApiException(r.statusCode,'device_remove_failed'); }

  AccountSession _session(http.Response r) {
    if (r.statusCode >= 400) {
      throw AccountApiException(r.statusCode, 'server_rejected');
    }
    final j = jsonDecode(r.body);
    final u = j['user'];
    final s = j['session'];
    return AccountSession(
      AccountUser(
        id: u['id'],
        displayName: u['displayName'],
        email: u['email'],
      ),
      s['accessToken'],
      s['refreshToken'],
    );
  }
}
