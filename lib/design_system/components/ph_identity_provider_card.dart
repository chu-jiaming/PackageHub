import 'package:flutter/material.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_radius.dart';
import 'package:packagehub/design_system/tokens/ph_sizes.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
import 'package:packagehub/design_system/tokens/ph_typography.dart';

class PHIdentityProviderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget icon;
  final VoidCallback? onTap;
  final Color? accentColor;

  const PHIdentityProviderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    final accent = accentColor ?? colors.iconAccent;
    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label: title,
      child: Material(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(PHRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PHRadius.md),
          child: Container(
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.symmetric(horizontal: PHSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: colors.borderDefault),
              borderRadius: BorderRadius.circular(PHRadius.md),
            ),
            child: Row(
              children: [
                IconTheme(
                  data: IconThemeData(color: accent, size: PHSizes.iconLarge),
                  child: icon,
                ),
                const SizedBox(width: PHSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: PHTypography.bodyEmphasis.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PHTypography.subheadline.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: PHSpacing.sm),
                Icon(
                  Icons.chevron_right,
                  color: colors.iconSecondary,
                  size: PHSizes.iconSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
