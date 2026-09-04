import 'package:packagehub/recognition/recognition_candidate.dart';
import 'package:packagehub/recognition/recognition_conflict.dart';
import 'package:packagehub/recognition/recognition_evidence.dart';

class RecognitionResolution {
  final Map<RecognitionField, RecognitionCandidate> winners;
  final List<RecognitionConflict> conflicts;

  const RecognitionResolution({required this.winners, required this.conflicts});

  bool get hasConflicts => conflicts.isNotEmpty;
}

class RecognitionCandidateResolver {
  const RecognitionCandidateResolver();

  RecognitionResolution resolve(Iterable<RecognitionCandidate> candidates) {
    final grouped = <RecognitionField, List<(RecognitionCandidate, int)>>{};
    var index = 0;
    for (final candidate in candidates) {
      grouped.putIfAbsent(candidate.field, () => []).add((candidate, index));
      index += 1;
    }
    final winners = <RecognitionField, RecognitionCandidate>{};
    final conflicts = <RecognitionConflict>[];
    for (final entry in grouped.entries) {
      final ordered = [...entry.value]
        ..sort(
          (a, b) => b.$1.priority != a.$1.priority
              ? b.$1.priority.compareTo(a.$1.priority)
              : a.$2.compareTo(b.$2),
        );
      final winner = ordered.first.$1;
      winners[entry.key] = winner;
      final alternatives = ordered
          .skip(1)
          .map((item) => item.$1)
          .where((candidate) => !_sameValue(candidate.value, winner.value))
          .toList();
      if (alternatives.isNotEmpty) {
        conflicts.add(
          RecognitionConflict(
            field: entry.key,
            winner: winner,
            alternatives: alternatives,
          ),
        );
      }
    }
    return RecognitionResolution(winners: winners, conflicts: conflicts);
  }

  bool _sameValue(Object a, Object b) => a == b;
}
