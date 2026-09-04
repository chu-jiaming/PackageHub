import 'package:flutter/material.dart';
import 'package:packagehub/account/account_pages.dart';
import 'package:packagehub/account/account_repository.dart';
import 'package:packagehub/account/account_state.dart';
import 'package:packagehub/subscription/subscription_presentation.dart';
import 'package:packagehub/subscription/subscription_entitlement.dart';
import 'package:packagehub/subscription/subscription_repository.dart';
import 'package:packagehub/account/account_user.dart';
import 'package:packagehub/account/devices_page.dart';
import 'package:packagehub/ui/adaptive.dart';

class AccountHub extends StatefulWidget {
  final AccountRepository accountRepository;
  final SubscriptionRepository subscriptionRepository;
  final VoidCallback onDismiss;

  const AccountHub({
    super.key,
    required this.accountRepository,
    required this.subscriptionRepository,
    required this.onDismiss,
  });

  @override
  State<AccountHub> createState() => _AccountHubState();
}

class _AccountHubState extends State<AccountHub> {
  double _dragDistance = 0;
  bool _isClosing = false;

  void _dismiss() {
    if (_isClosing) return;
    setState(() => _isClosing = true);
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (mounted) widget.onDismiss();
    });
  }

  void _open(Widget page) {
    widget.onDismiss();
    Navigator.of(context).push(adaptiveRoute(context, (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.accountRepository.current;
    final entitlement = widget.subscriptionRepository.current;
    final width = (MediaQuery.sizeOf(context).width * .84).clamp(300.0, 400.0);
    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            key: const Key('accountHubDimOverlay'),
            onTap: _dismiss,
            child: Container(color: Colors.black.withValues(alpha: .20)),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) =>
                    _dragDistance += details.delta.dx,
                onHorizontalDragEnd: (_) {
                  if (_dragDistance < -60) _dismiss();
                  _dragDistance = 0;
                },
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  tween: Tween(
                    begin: _isClosing ? 0 : -1,
                    end: _isClosing ? -1 : 0,
                  ),
                  builder: (context, value, child) => Transform.translate(
                    offset: Offset(width * value, 0),
                    child: child,
                  ),
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    elevation: 12,
                    child: SizedBox(
                      width: width,
                      height: double.infinity,
                      child: _DrawerContent(
                        state: state,
                        entitlement: entitlement,
                        onAccount: () => _open(
                          AccountPage(
                            accountRepository: widget.accountRepository,
                          ),
                        ),
                        onSubscription: () => _open(
                          SubscriptionPage(
                            subscriptionRepository:
                                widget.subscriptionRepository,
                            accountRepository: widget.accountRepository,
                          ),
                        ),
                        onDevices: () => _open(
                          DevicesPage(
                            accountRepository: widget.accountRepository,
                          ),
                        ),
                        onDataPrivacy: () => _open(const DataPrivacyPage()),
                        onSettings: () => _open(const SettingsPage()),
                        onHelp: () => _open(const HelpFeedbackPage()),
                        onAbout: () => _open(const AboutPage()),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerContent extends StatelessWidget {
  final AccountState state;
  final SubscriptionEntitlement entitlement;
  final VoidCallback onAccount,
      onSubscription,
      onDevices,
      onDataPrivacy,
      onSettings,
      onHelp,
      onAbout;
  const _DrawerContent({
    required this.state,
    required this.entitlement,
    required this.onAccount,
    required this.onSubscription,
    required this.onDevices,
    required this.onDataPrivacy,
    required this.onSettings,
    required this.onHelp,
    required this.onAbout,
  });

  @override
  Widget build(BuildContext context) {
    final user = state.user;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        _Header(user: user, signedIn: state.isSignedIn),
        const SizedBox(height: 20),
        Semantics(
          button: true,
          label: '${SubscriptionPresentation.title(entitlement)}，查看订阅权益',
          child: Card(
            child: ListTile(
              title: Text(SubscriptionPresentation.title(entitlement)),
              subtitle: Text(SubscriptionPresentation.subtitle(entitlement)),
              trailing: const Icon(Icons.chevron_right),
              onTap: onSubscription,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _Group(
          rows: [
            _Row('账号信息', Icons.person_outline, onAccount),
            _Row('订阅与权益', Icons.star_outline, onSubscription),
            _Row('登录设备', Icons.devices_outlined, onDevices),
            _Row('数据与隐私', Icons.lock_outline, onDataPrivacy),
            _Row('设置', Icons.settings_outlined, onSettings),
          ],
        ),
        const SizedBox(height: 16),
        _Group(
          rows: [
            _Row('帮助与反馈', Icons.help_outline, onHelp),
            _Row('关于 PackageHub', Icons.info_outline, onAbout),
          ],
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final AccountUser? user;
  final bool signedIn;
  const _Header({required this.user, required this.signedIn});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 28,
        child: signedIn
            ? Text((user?.displayName ?? 'U').substring(0, 1))
            : const Icon(Icons.person_outline),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              signedIn ? (user?.displayName ?? '用户') : '未登录',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              signedIn ? (user?.email ?? '') : '登录后可管理 Pro 订阅和登录设备',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ],
  );
}

class _Group extends StatelessWidget {
  final List<_Row> rows;
  const _Group({required this.rows});
  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          rows[i],
          if (i < rows.length - 1) const Divider(height: 1, indent: 56),
        ],
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _Row(this.title, this.icon, this.onTap);
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: title,
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
