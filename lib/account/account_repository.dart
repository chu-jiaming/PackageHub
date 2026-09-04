import 'account_state.dart';
import 'account_device.dart';

/// Future boundary: replace the mock with the real account integration.
abstract class AccountRepository {
  AccountState get current;
  String? get accessToken => null;
  Stream<AccountState> get changes => Stream<AccountState>.value(current);
  Future<void> restoreSession() async {}
  Future<void> signInWithApple() async => throw UnimplementedError();
  Future<void> signOut() async {}
  Future<void> deleteAccount() async => throw UnimplementedError();
  Future<List<AccountDevice>> loadDevices() async => <AccountDevice>[];
  Future<String?> storeKitAppAccountToken() async => null;
}
