import 'package:flutter/cupertino.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_sizes.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
import 'package:packagehub/design_system/tokens/ph_typography.dart';

enum PHDetailRowStyle { standard, subdued, danger }

class PHDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final PHDetailRowStyle style;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showSeparator;

  const PHDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.style = PHDetailRowStyle.standard,
    this.trailing,
    this.onTap,
    this.showSeparator = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    final valueColor = switch (style) {
      PHDetailRowStyle.standard => colors.textPrimary,
      PHDetailRowStyle.subdued => colors.textSecondary,
      PHDetailRowStyle.danger => colors.textDanger,
    };
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: PHSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: PHSizes.labelColumn,
            child: Text(
              label,
              style: PHTypography.subheadline.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: PHSpacing.md),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: PHTypography.subheadline.copyWith(color: valueColor),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: PHSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label: '$label $value',
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        decoration: BoxDecoration(
          border: showSeparator
              ? Border(bottom: BorderSide(color: colors.separatorDefault))
              : null,
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 58),
          onPressed: onTap,
          child: content,
        ),
      ),
    );
  }
}
