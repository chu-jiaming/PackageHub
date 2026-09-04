import 'package:flutter/material.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_radius.dart';

import 'ph_section_header.dart';

/// A surface container for related presentation rows.
class PHGroupedSection extends StatelessWidget {
  final String? title;
  final Widget? header;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  const PHGroupedSection({
    super.key,
    this.title,
    this.header,
    required this.children,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    assert(title == null || header == null);
    final resolvedHeader =
        header ?? (title == null ? null : PHSectionHeader(title: title!));
    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?resolvedHeader,
          ClipRRect(
            borderRadius: BorderRadius.circular(PHRadius.md),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.bgSurface,
                border: Border.all(color: colors.borderDefault),
                borderRadius: BorderRadius.circular(PHRadius.md),
              ),
              child: Column(children: children),
            ),
          ),
        ],
      ),
    );
  }
}
