import 'package:flutter/material.dart';
import 'package:packagehub/core/launcher/identity_launcher.dart';
import 'package:packagehub/models/identity_provider.dart';

class IdentityHubPage extends StatelessWidget {
  final IdentityLauncherApi launcher;

  const IdentityHubPage({super.key, required this.launcher});

  @override
  Widget build(BuildContext context) {
    const providers = [
      IdentityProvider.taobao,
      IdentityProvider.pinduoduo,
      IdentityProvider.cainiao,
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('身份码')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: providers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _ProviderCard(provider: providers[index], launcher: launcher),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final IdentityProvider provider;
  final IdentityLauncherApi launcher;

  const _ProviderCard({required this.provider, required this.launcher});

  Future<void> _open(BuildContext context) async {
    final result = await launcher.openIdentityCode(provider);
    if (!context.mounted || result == IdentityLaunchResult.openedIdentityCode) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('无法直达${provider.metadata.displayName}身份码'),
        content: const Text('平台可能更新了身份码入口。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _open(context);
            },
            child: const Text('重新尝试'),
          ),
          if (provider != IdentityProvider.cainiao)
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await launcher.openAppFallback(provider);
              },
              child: Text('打开${provider.metadata.displayName}'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metadata = provider.metadata;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                metadata.icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metadata.displayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metadata.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
