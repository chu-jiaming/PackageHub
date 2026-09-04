import 'package:flutter/material.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
import 'package:packagehub/design_system/tokens/ph_typography.dart';

class PHEmptyState extends StatelessWidget {
  final Widget? icon;
  final String title;
  final String? message;
  final Widget? action;

  const PHEmptyState({
    super.key,
    required this.title,
    this.icon,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    return Semantics(
      container: true,
      label: message == null ? title : '$title，$message',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(PHSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme(
                data: IconThemeData(color: colors.iconSecondary, size: 40),
                child: icon ?? const Icon(Icons.inventory_2_outlined),
              ),
              const SizedBox(height: PHSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: PHTypography.title3.copyWith(color: colors.textPrimary),
              ),
              if (message != null) ...[
                const SizedBox(height: PHSpacing.xs),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: PHTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: PHSpacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
