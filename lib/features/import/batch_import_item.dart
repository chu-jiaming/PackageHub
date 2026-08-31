import 'package:packagehub/models/pickup_credential_draft.dart';

enum BatchImportStatus { pending, recognizing, success, failed }

class BatchImportItem {
  final String imagePath;
  final BatchImportStatus status;
  final PickupCredentialDraft? draft;
  final String? errorMessage;

  const BatchImportItem({
    required this.imagePath,
    this.status = BatchImportStatus.pending,
    this.draft,
    this.errorMessage,
  });

  BatchImportItem copyWith({
    String? imagePath,
    BatchImportStatus? status,
    PickupCredentialDraft? draft,
    String? errorMessage,
    bool clearDraft = false,
    bool clearErrorMessage = false,
  }) {
    return BatchImportItem(
      imagePath: imagePath ?? this.imagePath,
      status: status ?? this.status,
      draft: clearDraft ? null : draft ?? this.draft,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
