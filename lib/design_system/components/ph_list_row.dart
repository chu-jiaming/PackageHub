import 'package:flutter/cupertino.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_sizes.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
import 'package:packagehub/design_system/tokens/ph_typography.dart';

class PHListRow extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool showSeparator;

  const PHListRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.showSeparator = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    final chevron = showChevron
        ? Icon(
            CupertinoIcons.chevron_right,
            size: PHSizes.iconSmall,
            color: colors.iconSecondary,
          )
        : null;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: PHSpacing.md),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: PHSpacing.md),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PHTypography.footnote.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: PHTypography.caption2.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: PHSpacing.sm),
            trailing!,
          ],
          if (chevron != null) ...[
            const SizedBox(width: PHSpacing.sm),
            chevron,
          ],
        ],
      ),
    );

    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label: title,
      child: Container(
        constraints: const BoxConstraints(minHeight: PHSizes.minInteractive),
        decoration: BoxDecoration(
          border: showSeparator
              ? Border(bottom: BorderSide(color: colors.separatorDefault))
              : null,
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, PHSizes.minInteractive),
          alignment: Alignment.center,
          pressedOpacity: 0.55,
          onPressed: onTap,
          child: content,
        ),
      ),
    );
  }
}
