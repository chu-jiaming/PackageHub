import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:packagehub/models/pickup_credential.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

class PickupCredentialCard extends StatelessWidget {
  final PickupCredential credential;
  final bool isSelectionMode;
  final bool isSelected;
  final bool isUpdating;
  final VoidCallback onTap;
  final ValueChanged<bool?> onSelectionChanged;
  final VoidCallback onDelete;
  final VoidCallback? onMarkPickedUp;
  final VoidCallback? onMarkPending;
  final bool showCourierCompany;

  const PickupCredentialCard({
    super.key,
    required this.credential,
    required this.isSelectionMode,
    required this.isSelected,
    required this.isUpdating,
    required this.onTap,
    required this.onSelectionChanged,
    required this.onDelete,
    required this.onMarkPickedUp,
    required this.onMarkPending,
    this.showCourierCompany = true,
  });

  @override
  Widget build(BuildContext context) {
    final card = _CredentialCardContent(
      credential: credential,
      isSelectionMode: isSelectionMode,
      isSelected: isSelected,
      isUpdating: isUpdating,
      onTap: onTap,
      onSelectionChanged: onSelectionChanged,
      onMarkPickedUp: onMarkPickedUp,
      onMarkPending: onMarkPending,
      showCourierCompany: showCourierCompany,
    );

    if (isSelectionMode) {
      return card;
    }

    return Slidable(
      key: Key('credentialSlidable-${credential.id ?? 'new'}'),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.28,
        children: [
          SlidableAction(
            key: Key('credentialDeleteAction-${credential.id ?? 'new'}'),
            onPressed: (_) => onDelete(),
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            icon: Icons.delete_outline,
            label: '删除',
          ),
        ],
      ),
      child: card,
    );
  }
}

class _CredentialCardContent extends StatelessWidget {
  final PickupCredential credential;
  final bool isSelectionMode;
  final bool isSelected;
  final bool isUpdating;
  final VoidCallback onTap;
  final ValueChanged<bool?> onSelectionChanged;
  final VoidCallback? onMarkPickedUp;
  final VoidCallback? onMarkPending;
  final bool showCourierCompany;

  const _CredentialCardContent({
    required this.credential,
    required this.isSelectionMode,
    required this.isSelected,
    required this.isUpdating,
    required this.onTap,
    required this.onSelectionChanged,
    required this.onMarkPickedUp,
    required this.onMarkPending,
    required this.showCourierCompany,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key('credentialCard-${credential.id ?? 'new'}'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSelectionMode) ...[
                Checkbox(
                  key: Key('credentialSelectionCheckbox-${credential.id}'),
                  value: isSelected,
                  onChanged: onSelectionChanged,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(child: _buildCredentialBody(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialBody(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pickupCode = credential.pickupCode ?? '未识别取件码';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showCourierCompany) ...[
          Text(
            credential.courierCompany.displayName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Semantics(
          label: '取件码 $pickupCode',
          child: Text(
            pickupCode,
            style: TextStyle(
              fontSize: 29,
              height: 1.1,
              letterSpacing: pickupCode.length > 8 ? -0.5 : 0,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
        ),
        if (credential.trackingNumber != null) ...[
          const SizedBox(height: 8),
          Text(
            credential.trackingNumber!,
            style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                credential.status.displayName,
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ),
            if (!isSelectionMode &&
                (onMarkPickedUp != null || onMarkPending != null))
              onMarkPickedUp != null
                  ? Semantics(
                      button: true,
                      label: '标记为已取件',
                      child: Tooltip(
                        message: '标记为已取件',
                        child: IconButton.filledTonal(
                          key: Key(
                            'credentialLifecycleButton-${credential.id}',
                          ),
                          onPressed: isUpdating ? null : onMarkPickedUp,
                          icon: const Icon(Icons.check),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(8),
                          tooltip: '标记为已取件',
                        ),
                      ),
                    )
                  : FilledButton.tonal(
                      key: Key('credentialLifecycleButton-${credential.id}'),
                      onPressed: isUpdating ? null : onMarkPending,
                      child: Text(isUpdating ? '更新中...' : '恢复待取件'),
                    ),
          ],
        ),
      ],
    );
  }
}
