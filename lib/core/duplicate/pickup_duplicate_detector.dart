import 'package:packagehub/core/duplicate/tracking_number_normalizer.dart';
import 'package:packagehub/core/repository/pickup_credential_repository.dart';
import 'package:packagehub/models/pickup_credential.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

enum DuplicateKind { existing, withinBatch }

class DuplicateCredentialMatch {
  final int incomingIndex;
  final PickupCredentialDraft incoming;
  final PickupCredential? existingCredential;
  final int? otherIncomingIndex;
  final PickupCredentialDraft? otherIncoming;
  final DuplicateKind kind;

  const DuplicateCredentialMatch.existing({
    required this.incomingIndex,
    required this.incoming,
    required PickupCredential this.existingCredential,
  }) : otherIncomingIndex = null,
       otherIncoming = null,
       kind = DuplicateKind.existing;

  const DuplicateCredentialMatch.withinBatch({
    required this.incomingIndex,
    required this.incoming,
    required int this.otherIncomingIndex,
    required PickupCredentialDraft this.otherIncoming,
  }) : existingCredential = null,
       kind = DuplicateKind.withinBatch;
}

class DuplicateCheckResult {
  final List<PickupCredentialDraft> originalDrafts;
  final List<DuplicateCredentialMatch> duplicates;

  const DuplicateCheckResult({
    required this.originalDrafts,
    required this.duplicates,
  });

  bool get hasDuplicates => duplicates.isNotEmpty;

  List<PickupCredentialDraft> get unique {
    final duplicateIndexes = duplicates
        .map((duplicate) => duplicate.incomingIndex)
        .toSet();
    return [
      for (var index = 0; index < originalDrafts.length; index += 1)
        if (!duplicateIndexes.contains(index)) originalDrafts[index],
    ];
  }

  List<PickupCredentialDraft> draftsForKeptDuplicates(
    Set<int> keptDuplicateIndexes,
  ) {
    final duplicateIndexes = duplicates
        .map((duplicate) => duplicate.incomingIndex)
        .toSet();

    return [
      for (var index = 0; index < originalDrafts.length; index += 1)
        if (!duplicateIndexes.contains(index) ||
            keptDuplicateIndexes.contains(index))
          originalDrafts[index],
    ];
  }
}

class PickupDuplicateDetector {
  final PickupCredentialRepositoryApi repository;

  const PickupDuplicateDetector({required this.repository});

  Future<DuplicateCheckResult> check(List<PickupCredentialDraft> drafts) async {
    final duplicates = <DuplicateCredentialMatch>[];
    final existingCandidatesByTracking = <String, List<PickupCredential>>{};
    final seenIncomingByTracking = <String, List<_IncomingCandidate>>{};

    for (var index = 0; index < drafts.length; index += 1) {
      final draft = drafts[index];
      final normalizedTracking = normalizeTrackingNumber(draft.trackingNumber);
      if (normalizedTracking == null) {
        continue;
      }

      final existingCandidates =
          existingCandidatesByTracking[normalizedTracking] ??= await repository
              .findByTrackingNumber(normalizedTracking);
      final existingDuplicate = existingCandidates
          .where(
            (credential) => isDuplicatePair(
              incomingCourier: draft.courierCompany,
              incomingTrackingNumber: draft.trackingNumber,
              existingCourier: credential.courierCompany,
              existingTrackingNumber: credential.trackingNumber,
            ),
          )
          .firstOrNull;

      if (existingDuplicate != null) {
        duplicates.add(
          DuplicateCredentialMatch.existing(
            incomingIndex: index,
            incoming: draft,
            existingCredential: existingDuplicate,
          ),
        );
        _rememberIncoming(
          seenIncomingByTracking,
          normalizedTracking,
          index,
          draft,
        );
        continue;
      }

      final seenDuplicate = seenIncomingByTracking[normalizedTracking]
          ?.where(
            (candidate) => isDuplicatePair(
              incomingCourier: draft.courierCompany,
              incomingTrackingNumber: draft.trackingNumber,
              existingCourier: candidate.draft.courierCompany,
              existingTrackingNumber: candidate.draft.trackingNumber,
            ),
          )
          .firstOrNull;

      if (seenDuplicate != null) {
        duplicates.add(
          DuplicateCredentialMatch.withinBatch(
            incomingIndex: index,
            incoming: draft,
            otherIncomingIndex: seenDuplicate.index,
            otherIncoming: seenDuplicate.draft,
          ),
        );
      }

      _rememberIncoming(
        seenIncomingByTracking,
        normalizedTracking,
        index,
        draft,
      );
    }

    return DuplicateCheckResult(
      originalDrafts: List.unmodifiable(drafts),
      duplicates: List.unmodifiable(duplicates),
    );
  }
}

bool isDuplicatePair({
  required CourierCompany incomingCourier,
  required String? incomingTrackingNumber,
  required CourierCompany existingCourier,
  required String? existingTrackingNumber,
}) {
  final incomingTracking = normalizeTrackingNumber(incomingTrackingNumber);
  final existingTracking = normalizeTrackingNumber(existingTrackingNumber);

  if (incomingTracking == null || existingTracking == null) {
    return false;
  }

  if (incomingTracking != existingTracking) {
    return false;
  }

  return incomingCourier == existingCourier ||
      incomingCourier == CourierCompany.unknown ||
      existingCourier == CourierCompany.unknown;
}

void _rememberIncoming(
  Map<String, List<_IncomingCandidate>> seenIncomingByTracking,
  String normalizedTracking,
  int index,
  PickupCredentialDraft draft,
) {
  final candidates = seenIncomingByTracking.putIfAbsent(
    normalizedTracking,
    () => [],
  );
  candidates.add(_IncomingCandidate(index: index, draft: draft));
}

class _IncomingCandidate {
  final int index;
  final PickupCredentialDraft draft;

  const _IncomingCandidate({required this.index, required this.draft});
}
