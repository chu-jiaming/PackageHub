import 'package:flutter/material.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_radius.dart';
import 'package:packagehub/design_system/tokens/ph_sizes.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
import 'package:packagehub/design_system/tokens/ph_typography.dart';

enum PHPackageCardState { active, completed }

/// The presentation-only PackageHub package card.
class PHPackageCard extends StatelessWidget {
  final PHPackageCardState state;
  final String? pickupCode;
  final String? trackingNumber;
  final String? location;
  final VoidCallback? onComplete;
  final VoidCallback? onTap;
  final Widget? trailingAction;
  final String? statusLabel;
  final Key? completeActionKey;
  final Key? cardKey;

  const PHPackageCard({
    super.key,
    required this.state,
    required this.pickupCode,
    required this.trackingNumber,
    required this.location,
    required this.onComplete,
    this.onTap,
    this.trailingAction,
    this.statusLabel,
    this.completeActionKey,
    this.cardKey,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    final content = Padding(
      padding: const EdgeInsets.all(PHSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: PHSizes.topHeight,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Semantics(
                          label: '取件码 ${pickupCode ?? '未识别取件码'}',
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              pickupCode ?? '未识别取件码',
                              maxLines: 1,
                              style: PHTypography.title1.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (statusLabel != null ||
                          state == PHPackageCardState.completed) ...[
                        const SizedBox(width: PHSpacing.sm),
                        Flexible(
                          child: Text(
                            statusLabel ??
                                (state == PHPackageCardState.completed
                                    ? '已取件'
                                    : ''),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PHTypography.caption2.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: PHSpacing.sm),
                trailingAction ?? _completeAction(colors),
              ],
            ),
          ),
          Divider(
            height: PHSizes.separator,
            thickness: PHSizes.separator,
            color: colors.separatorDefault,
          ),
          _infoRow('运单号', trackingNumber, colors),
          _infoRow('位置', location, colors),
        ],
      ),
    );

    return Semantics(
      container: true,
      child: Material(
        color: state == PHPackageCardState.completed
            ? colors.bgSurfaceSecondary
            : colors.bgSurface,
        borderRadius: BorderRadius.circular(PHRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PHRadius.lg),
          child: Container(
            key: cardKey,
            width: double.infinity,
            constraints: const BoxConstraints(
              minHeight: PHSizes.cardReferenceHeight,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PHRadius.lg),
              border: Border.all(
                color: colors.borderDefault,
                width: PHSizes.stroke,
              ),
            ),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _completeAction(PHColorScheme colors) {
    final enabled = state == PHPackageCardState.active && onComplete != null;
    return Semantics(
      button: enabled,
      label: enabled ? '标记为已取件' : '已取件',
      child: SizedBox(
        width: PHSizes.completeAction,
        height: PHSizes.completeAction,
        child: IconButton(
          key: completeActionKey ?? const Key('phPackageCardCompleteAction'),
          onPressed: enabled ? onComplete : null,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            backgroundColor: enabled
                ? colors.bgSurfaceSecondary
                : colors.bgDisabled,
            foregroundColor: colors.iconPrimary,
            shape: const CircleBorder(),
          ),
          icon: const Icon(Icons.check, size: 20),
          tooltip: enabled ? '标记为已取件' : '已取件',
        ),
      ),
    );
  }

  Widget _infoRow(String label, String? value, PHColorScheme colors) {
    return SizedBox(
      height: PHSizes.rowHeight,
      child: Row(
        children: [
          SizedBox(
            width: PHSizes.labelColumn,
            child: Text(
              label,
              style: PHTypography.caption2.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PHTypography.footnote.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
