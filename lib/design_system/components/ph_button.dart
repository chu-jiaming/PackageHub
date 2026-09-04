import 'package:flutter/cupertino.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
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
    final colors = PHColorScheme.of(context);
    final enabled = onPressed != null && !isLoading;
    final foreground = switch (variant) {
      PHButtonVariant.primary ||
      PHButtonVariant.destructive => colors.textInverse,
      _ => colors.textAccent,
    };
    final background = switch (variant) {
      PHButtonVariant.primary => colors.bgAccent,
      PHButtonVariant.secondary => colors.bgAccentSubtle,
      PHButtonVariant.tertiary => CupertinoColors.transparent,
      PHButtonVariant.destructive => colors.bgDanger,
    };
    final height = switch (size) {
      PHButtonSize.small => PHSizes.controlSmall,
      PHButtonSize.medium => PHSizes.controlMedium,
      PHButtonSize.large => PHSizes.controlLarge,
    };
    final textStyle = PHTypography.footnote.copyWith(
      color: enabled ? foreground : colors.textDisabled,
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
          disabledColor: colors.bgDisabled,
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
