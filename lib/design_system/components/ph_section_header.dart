import 'package:flutter/cupertino.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
import 'package:packagehub/design_system/tokens/ph_typography.dart';

class PHSectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PHSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    final actionWidget =
        action ??
        (actionLabel == null
            ? null
            : CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 44),
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: PHTypography.subheadline.copyWith(
                    color: colors.textAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ));
    return Semantics(
      container: true,
      header: true,
      label: title,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          PHSpacing.md,
          PHSpacing.lg,
          PHSpacing.md,
          PHSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: PHTypography.subheadlineEmphasis.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            if (actionWidget != null) ...[
              const SizedBox(width: PHSpacing.sm),
              actionWidget,
            ],
          ],
        ),
      ),
    );
  }
}
