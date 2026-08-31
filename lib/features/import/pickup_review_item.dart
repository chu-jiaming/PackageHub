import 'package:packagehub/models/pickup_credential_draft.dart';

class PickupReviewItem {
  final String imagePath;
  final PickupCredentialDraft draft;

  const PickupReviewItem({required this.imagePath, required this.draft});

  PickupReviewItem copyWith({String? imagePath, PickupCredentialDraft? draft}) {
    return PickupReviewItem(
      imagePath: imagePath ?? this.imagePath,
      draft: draft ?? this.draft,
    );
  }
}
