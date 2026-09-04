import 'package:flutter/material.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_radius.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
import 'package:packagehub/design_system/tokens/ph_typography.dart';

class PHCourierSectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Widget? leading;
  final Widget? trailing;
  final Color? accentColor;

  const PHCourierSectionHeader({
    super.key,
    required this.title,
    this.count,
    this.leading,
    this.trailing,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    final accent = accentColor ?? colors.iconAccent;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PHSpacing.md,
        vertical: PHSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurfaceSecondary,
        borderRadius: BorderRadius.circular(PHRadius.sm),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            IconTheme(
              data: IconThemeData(color: accent, size: 18),
              child: leading!,
            ),
            const SizedBox(width: PHSpacing.sm),
          ],
          Expanded(
            child: Text(
              title,
              style: PHTypography.subheadlineEmphasis.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          if (count != null)
            Text(
              '$count',
              style: PHTypography.caption1.copyWith(
                color: colors.textSecondary,
              ),
            ),
          if (trailing != null) ...[
            const SizedBox(width: PHSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
