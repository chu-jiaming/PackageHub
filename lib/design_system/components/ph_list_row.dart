import 'package:flutter/cupertino.dart';
import 'package:packagehub/design_system/tokens/ph_colors.dart';
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

  const PHListRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final chevron = showChevron
        ? const Icon(
            CupertinoIcons.chevron_right,
            size: PHSizes.iconSmall,
            color: PHColors.textTertiary,
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
                Text(title, style: PHTypography.footnote),
                if (subtitle != null)
                  Text(subtitle!, style: PHTypography.caption2),
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
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: PHColors.separatorDefault)),
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
