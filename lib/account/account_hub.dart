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
import 'package:packagehub/design_system/components/ph_badge.dart';
import 'package:packagehub/design_system/components/ph_grouped_section.dart';
import 'package:packagehub/design_system/components/ph_icon_button.dart';
import 'package:packagehub/design_system/components/ph_list_row.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
import 'package:packagehub/design_system/tokens/ph_typography.dart';

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
    final colors = PHColorScheme.of(context);
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
                    color: colors.bgSurface,
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
                        onDismiss: _dismiss,
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
      onAbout,
      onDismiss;
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
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final user = state.user;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        _Header(user: user, signedIn: state.isSignedIn, onDismiss: onDismiss),
        const SizedBox(height: PHSpacing.lg),
        PHGroupedSection(
          children: [
            PHListRow(
              title: SubscriptionPresentation.title(entitlement),
              subtitle: SubscriptionPresentation.subtitle(entitlement),
              trailing: PHBadge(
                label: entitlement.isPro ? 'Pro' : 'Free',
                variant: entitlement.isPro
                    ? PHBadgeVariant.success
                    : PHBadgeVariant.neutral,
              ),
              onTap: onSubscription,
              showSeparator: false,
            ),
          ],
        ),
        const SizedBox(height: PHSpacing.lg),
        PHGroupedSection(
          children: [
            _row('账号信息', Icons.person_outline, onAccount),
            _row('订阅与权益', Icons.star_outline, onSubscription),
            _row('登录设备', Icons.devices_outlined, onDevices),
            _row('数据与隐私', Icons.lock_outline, onDataPrivacy),
            _row('设置', Icons.settings_outlined, onSettings),
          ],
        ),
        const SizedBox(height: PHSpacing.md),
        PHGroupedSection(
          children: [
            _row('帮助与反馈', Icons.help_outline, onHelp),
            _row('关于 PackageHub', Icons.info_outline, onAbout),
          ],
        ),
      ],
    );
  }

  Widget _row(String title, IconData icon, VoidCallback onTap) {
    return PHListRow(
      leading: Icon(icon),
      title: title,
      onTap: onTap,
      showSeparator: title != '设置' && title != '关于 PackageHub',
    );
  }
}

class _Header extends StatelessWidget {
  final AccountUser? user;
  final bool signedIn;
  final VoidCallback onDismiss;
  const _Header({
    required this.user,
    required this.signedIn,
    required this.onDismiss,
  });
  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: colors.bgAccentSubtle,
          foregroundColor: colors.iconAccent,
          child: signedIn
              ? Text((user?.displayName ?? 'U').substring(0, 1))
              : const Icon(Icons.person_outline),
        ),
        const SizedBox(width: PHSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                signedIn ? (user?.displayName ?? '用户') : '未登录',
                style: PHTypography.title3.copyWith(color: colors.textPrimary),
              ),
              Text(
                signedIn ? (user?.email ?? '') : '登录后可管理 Pro 订阅和登录设备',
                style: PHTypography.footnote.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        PHIconButton(
          icon: const Icon(Icons.close),
          semanticsLabel: '关闭账户面板',
          onPressed: onDismiss,
        ),
      ],
    );
  }
}
