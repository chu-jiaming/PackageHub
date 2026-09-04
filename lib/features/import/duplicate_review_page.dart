import 'package:flutter/material.dart';
import 'package:packagehub/core/duplicate/pickup_duplicate_detector.dart';
import 'package:packagehub/design_system/components/ph_banner.dart';
import 'package:packagehub/design_system/components/ph_bottom_action_bar.dart';
import 'package:packagehub/design_system/components/ph_button.dart';
import 'package:packagehub/design_system/components/ph_grouped_section.dart';
import 'package:packagehub/design_system/components/ph_navigation_header.dart';
import 'package:packagehub/design_system/components/ph_section_header.dart';
import 'package:packagehub/design_system/components/ph_segmented_control.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
import 'package:packagehub/design_system/tokens/ph_typography.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

class DuplicateReviewPage extends StatefulWidget {
  final DuplicateCheckResult result;

  const DuplicateReviewPage({super.key, required this.result});

  @override
  State<DuplicateReviewPage> createState() => _DuplicateReviewPageState();
}

class _DuplicateReviewPageState extends State<DuplicateReviewPage> {
  final Set<int> _keptDuplicateIndexes = {};

  void _setKeepDuplicate(int incomingIndex, bool shouldKeep) {
    setState(() {
      if (shouldKeep) {
        _keptDuplicateIndexes.add(incomingIndex);
      } else {
        _keptDuplicateIndexes.remove(incomingIndex);
      }
    });
  }

  void _continue() {
    Navigator.of(context).pop<List<PickupCredentialDraft>>(
      widget.result.draftsForKeptDuplicates(_keptDuplicateIndexes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duplicates = widget.result.duplicates;

    return Scaffold(
      appBar: PHNavigationHeader(
        title: '重复凭证',
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            PHSpacing.md,
            PHSpacing.xs,
            PHSpacing.md,
            PHSpacing.md,
          ),
          children: [
            const PHSectionHeader(title: '发现重复取件凭证'),
            Text(
              '${duplicates.length} 个可能已经存在',
              key: const Key('duplicateReviewCountText'),
              style: PHTypography.subheadline.copyWith(
                color: PHColorScheme.of(context).textSecondary,
              ),
            ),
            const SizedBox(height: PHSpacing.md),
            for (final duplicate in duplicates) ...[
              _DuplicateConflictCard(
                key: Key('duplicateConflict_${duplicate.incomingIndex}'),
                duplicate: duplicate,
                shouldKeep: _keptDuplicateIndexes.contains(
                  duplicate.incomingIndex,
                ),
                onChanged: (shouldKeep) =>
                    _setKeepDuplicate(duplicate.incomingIndex, shouldKeep),
              ),
              const SizedBox(height: PHSpacing.sm),
            ],
          ],
        ),
      ),
      bottomNavigationBar: PHBottomActionBar(
        actions: [
          PHButton(
            key: const Key('continueDuplicateReviewButton'),
            onPressed: _continue,
            label: '继续添加',
          ),
        ],
      ),
    );
  }
}

class _DuplicateConflictCard extends StatelessWidget {
  final DuplicateCredentialMatch duplicate;
  final bool shouldKeep;
  final ValueChanged<bool> onChanged;

  const _DuplicateConflictCard({
    super.key,
    required this.duplicate,
    required this.shouldKeep,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    final draft = duplicate.incoming;
    final trackingNumber = draft.trackingNumber;
    final pickupCode = draft.pickupCode;

    return PHGroupedSection(
      children: [
        Padding(
          padding: const EdgeInsets.all(PHSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                draft.courierCompany.displayName,
                style: PHTypography.bodyEmphasis.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              if (trackingNumber != null) ...[
                const SizedBox(height: PHSpacing.xs),
                Text(
                  trackingNumber,
                  style: PHTypography.subheadline.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
              if (pickupCode != null) ...[
                const SizedBox(height: PHSpacing.xs),
                Text(
                  pickupCode,
                  style: PHTypography.subheadline.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: PHSpacing.sm),
              PHBanner(
                variant: PHBannerVariant.error,
                title: duplicate.kind == DuplicateKind.existing
                    ? '已存在于 PackageHub'
                    : '本次导入中重复',
                key: Key('duplicateReason_${duplicate.incomingIndex}'),
              ),
              const SizedBox(height: PHSpacing.md),
              PHSegmentedControl<bool>(
                key: Key('duplicateDecision_${duplicate.incomingIndex}'),
                value: shouldKeep,
                children: const {false: Text('跳过'), true: Text('仍然保留')},
                onValueChanged: (value) {
                  if (value != null) {
                    onChanged(value);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
