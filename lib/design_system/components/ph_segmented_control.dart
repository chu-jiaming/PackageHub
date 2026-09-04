import 'package:flutter/cupertino.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_radius.dart';
import 'package:packagehub/design_system/tokens/ph_sizes.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';

class PHSegmentedControl<T extends Object> extends StatelessWidget {
  final T value;
  final Map<T, Widget> children;
  final ValueChanged<T?>? onValueChanged;

  const PHSegmentedControl({
    super.key,
    required this.value,
    required this.children,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    return Semantics(
      container: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: PHSizes.segmentedControl),
        padding: const EdgeInsets.all(PHSpacing.xxs),
        decoration: BoxDecoration(
          color: colors.bgSurfaceSecondary,
          borderRadius: BorderRadius.circular(PHRadius.md),
        ),
        child: CupertinoSlidingSegmentedControl<T>(
          groupValue: value,
          children: children,
          onValueChanged: (value) => onValueChanged?.call(value),
          backgroundColor: colors.bgSurfaceSecondary,
          thumbColor: colors.bgSurface,
        ),
      ),
    );
  }
}
