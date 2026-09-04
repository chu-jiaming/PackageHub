import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:packagehub/account/account_repository.dart';
import 'package:packagehub/account/account_user.dart';
import 'package:packagehub/account/apple_sign_in_client.dart';
import 'package:packagehub/subscription/subscription_presentation.dart';
import 'package:packagehub/subscription/subscription_repository.dart';

void showPhaseOneNotice(BuildContext context, String message) {
  showCupertinoDialog<void>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('好'),
        ),
      ],
    ),
  );
}

class AccountPage extends StatefulWidget {
  final AccountRepository accountRepository;
  const AccountPage({super.key, required this.accountRepository});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _busy = false;
  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted && e is! AppleSignInCancelled) {
        showPhaseOneNotice(
          context,
          e.toString().contains('configurationMissing')
              ? '账户服务尚未配置'
              : '暂时无法连接账户服务，请稍后再试。',
        );
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.accountRepository.current;
    return Scaffold(
      appBar: AppBar(title: const Text('账号信息')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!state.isSignedIn) ...[
            const _PageIcon(icon: Icons.person_outline),
            const SizedBox(height: 16),
            Text('未登录', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('登录将在 Pro 正式开放后用于管理订阅和设备'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => _run(widget.accountRepository.signInWithApple),
              child: Text(_busy ? '处理中…' : '使用 Apple 登录'),
            ),
          ] else ...[
            _AccountIdentity(user: state.user!),
            const SizedBox(height: 20),
            const ListTile(title: Text('Apple 账号')),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => _run(widget.accountRepository.signOut),
              child: const Text('退出登录'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy
                  ? null
                  : () async {
                      final confirmed = await showCupertinoDialog<bool>(
                        context: context,
                        builder: (c) => CupertinoAlertDialog(
                          title: const Text('删除 PackageHub 账号'),
                          content: const Text('将删除账户、会话和服务器资料。本机取件记录不会删除。'),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('取消'),
                              onPressed: () => Navigator.pop(c, false),
                            ),
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              child: const Text('删除 PackageHub 账号'),
                              onPressed: () => Navigator.pop(c, true),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && mounted) {
                        _run(widget.accountRepository.deleteAccount);
                      }
                    },
              child: const Text('删除账号', style: TextStyle(color: Colors.red)),
            ),
          ],
        ],
      ),
    );
  }
}

class SubscriptionPage extends StatelessWidget {
  final SubscriptionRepository subscriptionRepository;
  const SubscriptionPage({super.key, required this.subscriptionRepository});

  @override
  Widget build(BuildContext context) {
    final entitlement = subscriptionRepository.current;
    final isPro = entitlement.isPro;
    return Scaffold(
      appBar: AppBar(title: const Text('订阅与权益')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionCard(
            title: SubscriptionPresentation.title(entitlement),
            subtitle: SubscriptionPresentation.subtitle(entitlement),
            child: isPro
                ? Text(SubscriptionPresentation.date(entitlement.expiresAt))
                : const Text('解锁未来持续服务能力。'),
          ),
          const SizedBox(height: 24),
          Text(
            isPro ? '当前方案' : 'Pro 计划将包含',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final item in const [
            '无限待取件凭证',
            '批量标记已取件',
            '批量删除',
            '更多高级管理能力',
            '后续 Pro 功能',
          ])
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(item),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => showPhaseOneNotice(
              context,
              isPro ? '订阅管理将在订阅系统接入后开放。' : '订阅将在订阅系统接入后开放。',
            ),
            child: Text(isPro ? '管理订阅' : '了解 PackageHub Pro'),
          ),
        ],
      ),
    );
  }
}

class DataPrivacyPage extends StatelessWidget {
  const DataPrivacyPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('数据与隐私')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _StatusTile(
          title: '本地数据',
          status: '取件凭证保存在此设备',
          icon: Icons.phone_iphone,
        ),
        _StatusTile(
          title: 'OCR',
          status: '识别在设备端完成',
          icon: Icons.document_scanner_outlined,
        ),
        _StatusTile(
          title: '云同步',
          status: '当前版本未提供',
          icon: Icons.cloud_off_outlined,
        ),
        SizedBox(height: 20),
        Text('所有取件凭证仍仅存储在本机。PackageHub 当前不会自动上传 OCR 或取件数据。'),
      ],
    ),
  );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('设置')),
    body: ListView(
      children: [
        ListTile(
          leading: Icon(Icons.notifications_outlined),
          title: Text('提醒'),
        ),
        ListTile(
          leading: Icon(Icons.display_settings_outlined),
          title: Text('显示设置'),
        ),
      ],
    ),
  );
}

class HelpFeedbackPage extends StatelessWidget {
  const HelpFeedbackPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('帮助与反馈')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const ListTile(leading: Icon(Icons.help_outline), title: Text('常见问题')),
        const ListTile(
          leading: Icon(Icons.bug_report_outlined),
          title: Text('报告问题'),
        ),
        const ListTile(
          leading: Icon(Icons.lightbulb_outline),
          title: Text('功能建议'),
        ),
        const SizedBox(height: 16),
        const Text('反馈渠道将在后续版本开放。'),
      ],
    ),
  );
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('关于 PackageHub')),
    body: ListView(
      padding: EdgeInsets.all(24),
      children: [
        const _PageIcon(icon: Icons.inventory_2_outlined),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'PackageHub',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 24),
        const ListTile(title: Text('隐私'), subtitle: Text('核心取件数据默认仅存储在本机。')),
        const ListTile(title: Text('版本'), subtitle: Text('当前版本信息随应用构建注入。')),
      ],
    ),
  );
}

class _PageIcon extends StatelessWidget {
  final IconData icon;
  const _PageIcon({required this.icon});
  @override
  Widget build(BuildContext context) =>
      CircleAvatar(radius: 32, child: Icon(icon, size: 32));
}

class _AccountIdentity extends StatelessWidget {
  final AccountUser user;
  const _AccountIdentity({required this.user});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(child: Text((user.displayName ?? 'U').characters.first)),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.displayName ?? '用户',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (user.email != null)
            Text(user.email!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ],
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(subtitle),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class _StatusTile extends StatelessWidget {
  final String title, status;
  final IconData icon;
  const _StatusTile({
    required this.title,
    required this.status,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Text(status),
    ),
  );
}
