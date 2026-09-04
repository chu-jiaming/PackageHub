import 'account_user.dart';

enum AccountStatus { restoring, signedOut, signedIn }

class AccountState {
  final AccountStatus status;
  final AccountUser? user;

  const AccountState._({required this.status, this.user});

  const AccountState.signedOut() : this._(status: AccountStatus.signedOut);
  const AccountState.restoring() : this._(status: AccountStatus.restoring);
  const AccountState.signedIn(AccountUser user)
    : this._(status: AccountStatus.signedIn, user: user);

  bool get isSignedIn => status == AccountStatus.signedIn;
  bool get isRestoring => status == AccountStatus.restoring;
}
