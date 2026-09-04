import 'package:flutter/cupertino.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_radius.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
import 'package:packagehub/design_system/tokens/ph_typography.dart';

enum PHBadgeVariant { neutral, accent, success, warning, destructive }

class PHBadge extends StatelessWidget {
  final String label;
  final PHBadgeVariant variant;

  const PHBadge({
    super.key,
    required this.label,
    this.variant = PHBadgeVariant.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    final color = switch (variant) {
      PHBadgeVariant.neutral => colors.textSecondary,
      PHBadgeVariant.accent => colors.textAccent,
      PHBadgeVariant.success => colors.textSuccess,
      PHBadgeVariant.warning => colors.textWarning,
      PHBadgeVariant.destructive => colors.textDanger,
    };
    final background = switch (variant) {
      PHBadgeVariant.neutral => colors.bgSurfaceSecondary,
      PHBadgeVariant.accent => colors.bgAccentSubtle,
      PHBadgeVariant.success => colors.bgSuccessSubtle,
      PHBadgeVariant.warning => colors.bgWarningSubtle,
      PHBadgeVariant.destructive => colors.bgDangerSubtle,
    };
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: PHSpacing.sm,
          vertical: PHSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(PHRadius.full),
        ),
        child: Text(
          label,
          style: PHTypography.caption2.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
