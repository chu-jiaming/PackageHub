import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_radius.dart';
import 'package:packagehub/design_system/tokens/ph_sizes.dart';

enum PHIconButtonVariant { plain, tinted, destructive }

class PHIconButton extends StatelessWidget {
  final Widget icon;
  final String semanticsLabel;
  final String? tooltip;
  final VoidCallback? onPressed;
  final PHIconButtonVariant variant;

  const PHIconButton({
    super.key,
    required this.icon,
    required this.semanticsLabel,
    this.tooltip,
    required this.onPressed,
    this.variant = PHIconButtonVariant.plain,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    final foreground = switch (variant) {
      PHIconButtonVariant.destructive => colors.iconDanger,
      _ => colors.iconAccent,
    };
    final background = switch (variant) {
      PHIconButtonVariant.plain => CupertinoColors.transparent,
      PHIconButtonVariant.tinted => colors.bgAccentSubtle,
      PHIconButtonVariant.destructive => colors.bgDangerSubtle,
    };

    final button = Semantics(
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
          disabledColor: colors.bgDisabled,
          onPressed: onPressed,
          pressedOpacity: 0.55,
          child: IconTheme(
            data: IconThemeData(
              color: onPressed == null ? colors.iconDisabled : foreground,
              size: PHSizes.iconMedium,
            ),
            child: icon,
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
