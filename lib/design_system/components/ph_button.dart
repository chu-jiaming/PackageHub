import 'package:flutter/cupertino.dart';
import 'package:packagehub/design_system/tokens/ph_colors.dart';
import 'package:packagehub/design_system/tokens/ph_radius.dart';
import 'package:packagehub/design_system/tokens/ph_sizes.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
import 'package:packagehub/design_system/tokens/ph_typography.dart';

enum PHButtonVariant { primary, secondary, tertiary, destructive }

enum PHButtonSize { small, medium, large }

class PHButton extends StatelessWidget {
  final String label;
  final PHButtonVariant variant;
  final PHButtonSize size;
  final Widget? leading;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PHButton({
    super.key,
    required this.label,
    this.variant = PHButtonVariant.primary,
    this.size = PHButtonSize.medium,
    this.leading,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final foreground = switch (variant) {
      PHButtonVariant.primary ||
      PHButtonVariant.destructive => CupertinoColors.white,
      _ => PHColors.accent,
    };
    final background = switch (variant) {
      PHButtonVariant.primary => PHColors.accent,
      PHButtonVariant.secondary => PHColors.accent.withValues(alpha: 0.12),
      PHButtonVariant.tertiary => CupertinoColors.transparent,
      PHButtonVariant.destructive => PHColors.destructive,
    };
    final height = switch (size) {
      PHButtonSize.small => PHSizes.controlSmall,
      PHButtonSize.medium => PHSizes.controlMedium,
      PHButtonSize.large => PHSizes.controlLarge,
    };
    final textStyle = PHTypography.footnote.copyWith(
      color: enabled ? foreground : PHColors.textTertiary,
      fontWeight: FontWeight.w600,
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: PHSizes.minInteractive),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: PHSpacing.md),
          minimumSize: Size(0, height),
          borderRadius: BorderRadius.circular(PHRadius.md),
          color: background,
          disabledColor: PHColors.bgSurfaceSecondary,
          onPressed: enabled ? onPressed : null,
          pressedOpacity: 0.55,
          child: isLoading
              ? CupertinoActivityIndicator(color: foreground)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: PHSpacing.sm),
                    ],
                    Text(label, style: textStyle),
                  ],
                ),
        ),
      ),
    );
  }
}
