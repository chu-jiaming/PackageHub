import 'package:flutter/material.dart';
import 'package:packagehub/account/account_pages.dart';
import 'package:packagehub/subscription/subscription_repository.dart';

Future<bool> showProUpgradeSheet(
  BuildContext context, {
  required SubscriptionRepository subscriptionRepository,
  required String title,
  required String body,
  String secondaryLabel = '返回',
}) async {
  final openPro = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(body),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('proUpsellPrimaryButton'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('了解 PackageHub Pro'),
            ),
            TextButton(
              key: const Key('proUpsellSecondaryButton'),
              onPressed: () => Navigator.pop(context, false),
              child: Text(secondaryLabel),
            ),
          ],
        ),
      ),
    ),
  );
  if (openPro == true && context.mounted) {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SubscriptionPage(subscriptionRepository: subscriptionRepository),
      ),
    );
  }
  return openPro == true;
}
