import 'package:flutter/cupertino.dart';
import 'package:packagehub/design_system/tokens/ph_colors.dart';
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
    final color = switch (variant) {
      PHBadgeVariant.neutral => PHColors.textSecondary,
      PHBadgeVariant.accent => PHColors.accent,
      PHBadgeVariant.success => PHColors.success,
      PHBadgeVariant.warning => PHColors.warning,
      PHBadgeVariant.destructive => PHColors.destructive,
    };
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: PHSpacing.sm,
          vertical: PHSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
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
