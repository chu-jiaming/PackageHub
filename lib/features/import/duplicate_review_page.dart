import 'package:flutter/material.dart';
import 'package:packagehub/core/duplicate/pickup_duplicate_detector.dart';
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
      appBar: AppBar(title: const Text('重复凭证')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            const Text(
              '发现重复取件凭证',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '${duplicates.length} 个可能已经存在',
              key: const Key('duplicateReviewCountText'),
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
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
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('continueDuplicateReviewButton'),
                onPressed: _continue,
                child: const Text('继续添加'),
              ),
            ),
          ),
        ),
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
    final draft = duplicate.incoming;
    final trackingNumber = draft.trackingNumber;
    final pickupCode = draft.pickupCode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            draft.courierCompany.displayName,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          if (trackingNumber != null) ...[
            const SizedBox(height: 6),
            Text(trackingNumber),
          ],
          if (pickupCode != null) ...[
            const SizedBox(height: 4),
            Text(pickupCode, style: TextStyle(color: Colors.grey.shade700)),
          ],
          const SizedBox(height: 10),
          Text(
            duplicate.kind == DuplicateKind.existing
                ? '已存在于 PackageHub'
                : '本次导入中重复',
            key: Key('duplicateReason_${duplicate.incomingIndex}'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<bool>(
            key: Key('duplicateDecision_${duplicate.incomingIndex}'),
            segments: const [
              ButtonSegment(value: false, label: Text('跳过')),
              ButtonSegment(value: true, label: Text('仍然保留')),
            ],
            selected: {shouldKeep},
            onSelectionChanged: (selection) => onChanged(selection.single),
          ),
        ],
      ),
    );
  }
}
