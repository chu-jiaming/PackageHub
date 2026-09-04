import 'package:packagehub/models/pickup_credential_draft.dart';

enum BatchImportStatus { pending, recognizing, success, failed }

class BatchImportItem {
  final String imagePath;
  final BatchImportStatus status;
  final List<PickupCredentialDraft> drafts;
  final String? errorMessage;

  const BatchImportItem({
    required this.imagePath,
    this.status = BatchImportStatus.pending,
    this.drafts = const [],
    this.errorMessage,
  });

  BatchImportItem copyWith({
    String? imagePath,
    BatchImportStatus? status,
    List<PickupCredentialDraft>? drafts,
    String? errorMessage,
    bool clearDrafts = false,
    bool clearErrorMessage = false,
  }) {
    return BatchImportItem(
      imagePath: imagePath ?? this.imagePath,
      status: status ?? this.status,
      drafts: clearDrafts ? const [] : drafts ?? this.drafts,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
