import 'dart:async';
import 'package:packagehub/account/account_api_client.dart';
import 'package:packagehub/account/account_repository.dart';
import 'package:packagehub/account/secure_token_store.dart';
import 'subscription_entitlement.dart';
import 'subscription_repository.dart';
import 'storekit_client.dart';
import 'storekit_models.dart';
import 'subscription_state.dart';

/// The production key verifier is injected by the app build. Keeping this
/// boundary explicit prevents a cached StoreKit transaction from becoming an
/// entitlement by accident.
abstract interface class EntitlementTokenVerifier {
  Map<String, dynamic>? verify(String token, {required String userId, required String deviceId});
}
class RejectingEntitlementTokenVerifier implements EntitlementTokenVerifier {
  const RejectingEntitlementTokenVerifier();
  @override Map<String, dynamic>? verify(String token, {required String userId, required String deviceId}) => null;
}

class BackendSubscriptionRepository implements SubscriptionRepository {
  final AccountRepository account;
  final AccountApiClient api;
  final StoreKitClient storeKit;
  final EntitlementTokenStore tokenStore;
  final EntitlementTokenVerifier verifier;
  final _changes = StreamController<SubscriptionEntitlement>.broadcast();
  SubscriptionEntitlement _current = const SubscriptionEntitlement(state: SubscriptionState.free);
  BackendSubscriptionRepository({required this.account, required this.api, required this.storeKit, EntitlementTokenStore? tokenStore, required this.verifier}) : tokenStore = tokenStore ?? KeychainEntitlementTokenStore();
  @override SubscriptionEntitlement get current => _current;
  @override Stream<SubscriptionEntitlement> get changes => _changes.stream;
  void _set(SubscriptionEntitlement v) { if(v.state==_current.state&&v.productId==_current.productId&&v.expiresAt==_current.expiresAt) return; _current=v; _changes.add(v); }
  SubscriptionEntitlement _from(BackendEntitlement e) => SubscriptionEntitlement(state: _state(e.state),productId:e.productId,planDisplayName:e.planDisplayName,expiresAt:e.expiresAt==null?null:DateTime.tryParse(e.expiresAt!),autoRenewEnabled:e.autoRenewEnabled);
  SubscriptionState _state(String s)=>switch(s){'trial'=>SubscriptionState.trial,'gracePeriod'=>SubscriptionState.gracePeriod,'billingRetry'=>SubscriptionState.billingRetry,'expired'=>SubscriptionState.expired,'revoked'=>SubscriptionState.revoked,_=>s=='active'?SubscriptionState.active:SubscriptionState.free};
  String? _access() => account.accessToken;
  @override Future<void> refresh() async { final a=_access(); final u=account.current.user; if(a==null||u==null){await tokenStore.clear();return _set(const SubscriptionEntitlement(state:SubscriptionState.free));} try{final e=await api.entitlement(a); if(e.signedEntitlementToken!=null) await tokenStore.save(e.signedEntitlementToken!); _set(_from(e));}catch(_){final t=await tokenStore.read(); final claims=t==null?null:verifier.verify(t,userId:u.id,deviceId:''); if(claims==null||DateTime.fromMillisecondsSinceEpoch((claims['exp'] as num).toInt()*1000).isBefore(DateTime.now())){_set(const SubscriptionEntitlement(state:SubscriptionState.free));}} }
  @override Future<StoreProduct?> loadProProduct()=>storeKit.loadProducts(['packagehub.pro']).then((p)=>p.where((x)=>x.id=='packagehub.pro').firstOrNull);
  @override Future<StorePurchaseResult> purchasePro() async { final r=await storeKit.purchase(productId:'packagehub.pro',appAccountToken:(await account.storeKitAppAccountToken())??''); if(r.status==StorePurchaseStatus.purchased&&r.signedTransaction!=null){final a=_access();if(a!=null) {await api.confirmTransaction(a,r.signedTransaction!); await refresh();}} return r; }
  @override Future<void> restorePurchases() async {await storeKit.restorePurchases(); await refresh();}
  Future<void> dispose() async {await _changes.close();}
}
