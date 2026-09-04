import 'package:flutter/material.dart';
import 'package:packagehub/account/account_pages.dart';
import 'package:packagehub/design_system/components/ph_bottom_sheet.dart';
import 'package:packagehub/design_system/components/ph_button.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
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
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (context) => SafeArea(
      child: PHBottomSheet(
        title: title,
        actions: [
          PHButton(
            key: const Key('proUpsellPrimaryButton'),
            onPressed: () => Navigator.pop(context, true),
            label: '了解 PackageHub Pro',
          ),
          PHButton(
            key: const Key('proUpsellSecondaryButton'),
            variant: PHButtonVariant.tertiary,
            onPressed: () => Navigator.pop(context, false),
            label: secondaryLabel,
          ),
        ],
        child: Text(
          body,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: PHColorScheme.of(context).textPrimary),
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
