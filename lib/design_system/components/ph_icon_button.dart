import 'package:flutter/cupertino.dart';
import 'package:packagehub/design_system/tokens/ph_colors.dart';
import 'package:packagehub/design_system/tokens/ph_radius.dart';
import 'package:packagehub/design_system/tokens/ph_sizes.dart';

enum PHIconButtonVariant { plain, tinted, destructive }

class PHIconButton extends StatelessWidget {
  final Widget icon;
  final String semanticsLabel;
  final VoidCallback? onPressed;
  final PHIconButtonVariant variant;

  const PHIconButton({
    super.key,
    required this.icon,
    required this.semanticsLabel,
    required this.onPressed,
    this.variant = PHIconButtonVariant.plain,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = switch (variant) {
      PHIconButtonVariant.destructive => PHColors.destructive,
      _ => PHColors.accent,
    };
    final background = switch (variant) {
      PHIconButtonVariant.plain => CupertinoColors.transparent,
      PHIconButtonVariant.tinted => PHColors.accent.withValues(alpha: 0.12),
      PHIconButtonVariant.destructive => PHColors.destructive.withValues(
        alpha: 0.12,
      ),
    };

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticsLabel,
      child: SizedBox(
        width: PHSizes.minInteractive,
        height: PHSizes.minInteractive,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(
            PHSizes.minInteractive,
            PHSizes.minInteractive,
          ),
          borderRadius: BorderRadius.circular(PHRadius.md),
          color: background,
          disabledColor: PHColors.bgSurfaceSecondary,
          onPressed: onPressed,
          pressedOpacity: 0.55,
          child: IconTheme(
            data: IconThemeData(
              color: onPressed == null ? PHColors.textTertiary : foreground,
              size: PHSizes.iconMedium,
            ),
            child: icon,
          ),
        ),
      ),
    );
  }
}
