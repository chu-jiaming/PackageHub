import 'package:flutter/material.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';

class PHBottomActionBar extends StatelessWidget {
  final List<Widget> actions;
  final Widget? leading;
  final EdgeInsetsGeometry padding;

  const PHBottomActionBar({
    super.key,
    required this.actions,
    this.leading,
    this.padding = const EdgeInsets.all(PHSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    return Material(
      color: colors.bgElevated,
      child: SafeArea(
        top: false,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.separatorDefault)),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: PHSpacing.sm),
              ],
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: PHSpacing.sm),
                Expanded(child: actions[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
