import 'package:flutter/material.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_radius.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
import 'package:packagehub/design_system/tokens/ph_typography.dart';

enum PHBottomSheetSizing { content, scrollable }

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
  final PHBottomSheetSizing sizing;
  final double maxHeightFactor;

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
    this.sizing = PHBottomSheetSizing.content,
    this.maxHeightFactor = .85,
  }) : assert(maxHeightFactor > 0 && maxHeightFactor <= 1);

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    return sizing == PHBottomSheetSizing.content
        ? _buildContentSized(context, colors)
        : _buildScrollable(
            context,
            colors,
            MediaQuery.sizeOf(context).height * maxHeightFactor,
          );
  }

  Widget _buildContentSized(BuildContext context, PHColorScheme colors) {
    return _surface(
      context,
      colors,
      Padding(
        padding: padding,
        child: Column(
          key: const Key('ph-bottom-sheet-content'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHandle(colors),
            _buildContentHeader(colors),
            child,
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollable(
    BuildContext context,
    PHColorScheme colors,
    double maxHeight,
  ) {
    return _surface(
      context,
      colors,
      ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: padding,
          child: Column(
            key: const Key('ph-bottom-sheet-content'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHandle(colors),
              _buildHeader(colors),
              Flexible(fit: FlexFit.loose, child: child),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _surface(BuildContext context, PHColorScheme colors, Widget child) {
    return Material(
      key: const Key('ph-bottom-sheet-surface'),
      color: colors.bgSurface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(PHRadius.xl),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: child,
      ),
    );
  }

  Widget _buildHandle(PHColorScheme colors) {
    return showDragHandle
        ? Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderStrong,
                borderRadius: BorderRadius.circular(PHRadius.full),
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  Widget _buildHeader(PHColorScheme colors) {
    final hasHeader = title != null || leading != null || trailing != null;
    if (!hasHeader) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDragHandle && (title != null || leading != null))
          const SizedBox(height: PHSpacing.md),
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
        const SizedBox(height: PHSpacing.md),
      ],
    );
  }

  Widget _buildContentHeader(PHColorScheme colors) {
    final hasHeader = title != null || leading != null || trailing != null;
    if (!hasHeader) return const SizedBox.shrink();
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Text(
            title!,
            style: PHTypography.title3.copyWith(color: colors.textPrimary),
          ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: PHTypography.subheadline.copyWith(
              color: colors.textSecondary,
            ),
          ),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDragHandle && (title != null || leading != null))
          const SizedBox(height: PHSpacing.md),
        if (leading == null && trailing == null)
          text
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ?leading,
              if (leading != null) const SizedBox(width: PHSpacing.sm),
              text,
              ?trailing,
            ],
          ),
        const SizedBox(height: PHSpacing.md),
      ],
    );
  }

  Widget _buildActions() {
    if (actions.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: PHSpacing.md),
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(height: PHSpacing.sm),
          actions[i],
        ],
      ],
    );
  }
}
