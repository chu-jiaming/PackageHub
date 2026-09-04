import 'package:flutter/material.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_radius.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
import 'package:packagehub/design_system/tokens/ph_typography.dart';

enum PHBannerVariant { info, warning, error }

class PHBanner extends StatelessWidget {
  final PHBannerVariant variant;
  final String title;
  final String? message;
  final Widget? leading;
  final Widget? action;
  final VoidCallback? onDismiss;

  const PHBanner({
    super.key,
    required this.variant,
    required this.title,
    this.message,
    this.leading,
    this.action,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    final foreground = switch (variant) {
      PHBannerVariant.info => colors.textAccent,
      PHBannerVariant.warning => colors.textWarning,
      PHBannerVariant.error => colors.textDanger,
    };
    final background = switch (variant) {
      PHBannerVariant.info => colors.bgAccentSubtle,
      PHBannerVariant.warning => colors.bgWarningSubtle,
      PHBannerVariant.error => colors.bgDangerSubtle,
    };
    return Semantics(
      container: true,
      label: message == null ? title : '$title，$message',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: PHSpacing.md,
          vertical: PHSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: foreground.withValues(alpha: .24)),
          borderRadius: BorderRadius.circular(PHRadius.md),
        ),
        child: Row(
          children: [
            leading ?? Icon(_iconForVariant(), color: foreground),
            const SizedBox(width: PHSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: PHTypography.subheadlineEmphasis.copyWith(
                      color: foreground,
                    ),
                  ),
                  if (message != null)
                    Text(
                      message!,
                      style: PHTypography.footnote.copyWith(color: foreground),
                    ),
                ],
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: PHSpacing.sm),
              action!,
            ],
            if (onDismiss != null)
              IconButton(
                tooltip: '关闭',
                onPressed: onDismiss,
                icon: Icon(Icons.close, color: foreground),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForVariant() {
    return switch (variant) {
      PHBannerVariant.info => Icons.info_outline,
      PHBannerVariant.warning => Icons.warning_amber_outlined,
      PHBannerVariant.error => Icons.error_outline,
    };
  }
}
