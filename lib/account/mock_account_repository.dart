import 'account_repository.dart';
import 'account_state.dart';
import 'account_device.dart';

class MockAccountRepository implements AccountRepository {
  @override
  final AccountState current;

  const MockAccountRepository({this.current = const AccountState.signedOut()});

  @override
  Stream<AccountState> get changes => Stream.value(current);
  @override
  Future<void> restoreSession() async {}
  @override
  Future<void> signInWithApple() async => throw UnimplementedError();
  @override
  Future<void> signOut() async {}
  @override
  Future<void> deleteAccount() async => throw UnimplementedError();
  @override
  Future<List<AccountDevice>> loadDevices() async => <AccountDevice>[];
}
