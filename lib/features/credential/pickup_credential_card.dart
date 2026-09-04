import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:packagehub/design_system/components/ph_package_card.dart';
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
    if (isSelectionMode) return card;
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
    final completed = credential.status == PickupStatus.pickedUp;
    final packageCard = PHPackageCard(
      state: completed
          ? PHPackageCardState.completed
          : PHPackageCardState.active,
      pickupCode: credential.pickupCode,
      trackingNumber: credential.trackingNumber,
      location: null,
      statusLabel: completed || credential.status == PickupStatus.unknown
          ? credential.status.displayName
          : null,
      onComplete: !isSelectionMode && !isUpdating ? onMarkPickedUp : null,
      completeActionKey: Key('credentialLifecycleButton-${credential.id}'),
      cardKey: Key('credentialCard-${credential.id}'),
      onTap: onTap,
      trailingAction: completed && !isSelectionMode && onMarkPending != null
          ? Semantics(
              button: true,
              label: '恢复待取件',
              child: Tooltip(
                message: '恢复待取件',
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    key: Key('credentialLifecycleButton-${credential.id}'),
                    onPressed: isUpdating ? null : onMarkPending,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.undo),
                    tooltip: '恢复待取件',
                  ),
                ),
              ),
            )
          : null,
    );

    return Row(
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
        Expanded(
          child: showCourierCompany
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      credential.courierCompany.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    packageCard,
                  ],
                )
              : packageCard,
        ),
      ],
    );
  }
}
