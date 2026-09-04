import 'package:flutter/material.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_radius.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
import 'package:packagehub/design_system/tokens/ph_typography.dart';

/// Surface and layout for a bottom sheet. Modal presentation is caller-owned.
class PHBottomSheet extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget child;
  final List<Widget> actions;
  final bool showDragHandle;
  final EdgeInsetsGeometry padding;

  const PHBottomSheet({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    required this.child,
    this.actions = const [],
    this.showDragHandle = true,
    this.padding = const EdgeInsets.fromLTRB(
      PHSpacing.lg,
      PHSpacing.sm,
      PHSpacing.lg,
      PHSpacing.lg,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    return Material(
      color: colors.bgSurface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(PHRadius.xl),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDragHandle)
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.borderStrong,
                    borderRadius: BorderRadius.circular(PHRadius.full),
                  ),
                ),
              ),
            if (showDragHandle && (title != null || leading != null))
              const SizedBox(height: PHSpacing.md),
            if (title != null || leading != null || trailing != null)
              Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: PHSpacing.sm),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            style: PHTypography.title3.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: PHTypography.subheadline.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            if (title != null || leading != null || trailing != null)
              const SizedBox(height: PHSpacing.md),
            child,
            if (actions.isNotEmpty) ...[
              const SizedBox(height: PHSpacing.md),
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(height: PHSpacing.sm),
                actions[i],
              ],
            ],
          ],
        ),
      ),
    );
  }
}
