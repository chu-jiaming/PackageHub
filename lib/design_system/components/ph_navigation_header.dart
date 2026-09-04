import 'package:flutter/cupertino.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_sizes.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
import 'package:packagehub/design_system/tokens/ph_typography.dart';

enum PHNavigationHeaderStyle { standard, largeTitle }

/// Presentation-only navigation header. Navigation is owned by the caller.
class PHNavigationHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final PHNavigationHeaderStyle style;
  final Widget? leading;
  final String title;
  final List<Widget> actions;

  const PHNavigationHeader({
    super.key,
    this.style = PHNavigationHeaderStyle.standard,
    this.leading,
    required this.title,
    this.actions = const [],
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(style == PHNavigationHeaderStyle.largeTitle ? 104 : 64);

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    final isLarge = style == PHNavigationHeaderStyle.largeTitle;
    final navigationContentHeight = isLarge ? 104.0 : 64.0;
    final titleStyle =
        (isLarge ? PHTypography.largeTitle : PHTypography.bodyEmphasis)
            .copyWith(color: colors.textPrimary);

    final header = Padding(
      padding: EdgeInsets.fromLTRB(
        PHSpacing.md,
        isLarge ? PHSpacing.md : PHSpacing.xs,
        PHSpacing.md,
        isLarge ? PHSpacing.md : PHSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: isLarge
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            _slot(leading!),
            const SizedBox(width: PHSpacing.sm),
          ] else if (!isLarge)
            const SizedBox(width: PHSizes.minInteractive),
          Expanded(
            child: Text(
              title,
              maxLines: isLarge ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              textAlign: isLarge || leading != null
                  ? TextAlign.left
                  : TextAlign.center,
              style: titleStyle,
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: PHSpacing.sm),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: PHSpacing.xs),
                  _actionSlot(actions[i]),
                ],
              ],
            ),
          ] else if (!isLarge)
            const SizedBox(width: PHSizes.minInteractive),
        ],
      ),
    );

    return Semantics(
      container: true,
      header: true,
      label: title,
      child: ColoredBox(
        color: colors.bgSurface,
        child: SafeArea(
          top: true,
          bottom: false,
          child: SizedBox(
            height: navigationContentHeight,
            child: Container(
              decoration: BoxDecoration(
                color: colors.bgSurface,
                border: Border(
                  bottom: BorderSide(color: colors.separatorDefault),
                ),
              ),
              child: Align(alignment: Alignment.bottomCenter, child: header),
            ),
          ),
        ),
      ),
    );
  }

  Widget _slot(Widget child) {
    return SizedBox(
      width: PHSizes.minInteractive,
      height: PHSizes.minInteractive,
      child: Center(child: child),
    );
  }

  Widget _actionSlot(Widget child) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: PHSizes.minInteractive,
        minHeight: PHSizes.minInteractive,
      ),
      child: child,
    );
  }
}
