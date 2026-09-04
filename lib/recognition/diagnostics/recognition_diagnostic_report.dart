import 'package:packagehub/models/pickup_credential_draft.dart';
import 'package:packagehub/recognition/credential_segment.dart';
import 'package:packagehub/recognition/pickup_code_anchor.dart';
import 'package:packagehub/recognition/recognition_candidate.dart';
import 'package:packagehub/recognition/recognition_conflict.dart';
import 'package:packagehub/recognition/recognition_evidence.dart';
import 'package:packagehub/recognition/recognition_context.dart';
import 'package:packagehub/recognition/recognition_rule.dart';

/// A deliberately metadata-first trace. It never stores the input OCR text.
class RecognitionDiagnosticReport {
  final int inputLength;
  final int lineCount;
  final int normalizedLength;
  final int normalizedLineCount;
  final List<PickupAnchorDiagnostic> anchors;
  final List<SegmentDiagnostic> segments;
  final List<CredentialDiagnostic> credentials;
  final List<String> warnings;

  const RecognitionDiagnosticReport({
    required this.inputLength,
    required this.lineCount,
    required this.normalizedLength,
    required this.normalizedLineCount,
    required this.anchors,
    required this.segments,
    required this.credentials,
    this.warnings = const [],
  });

  int get anchorCount => anchors.length;
  int get segmentCount => segments.length;
  int get credentialCount => credentials.length;
  int get conflictCount =>
      credentials.fold(0, (n, c) => n + c.conflicts.length);
}

class PickupAnchorDiagnostic {
  final int index;
  final String value;
  final String ruleId;
  final int priority;
  final int lineIndex;
  final int startOffset;
  final int endOffset;

  const PickupAnchorDiagnostic({
    required this.index,
    required this.value,
    required this.ruleId,
    required this.priority,
    required this.lineIndex,
    required this.startOffset,
    required this.endOffset,
  });

  factory PickupAnchorDiagnostic.fromAnchor(
    int index,
    PickupCodeAnchor anchor,
  ) => PickupAnchorDiagnostic(
    index: index,
    value: anchor.value,
    ruleId: anchor.ruleId,
    priority: anchor.priority,
    lineIndex: anchor.lineIndex,
    startOffset: anchor.startOffset,
    endOffset: anchor.endOffset,
  );
}

class SegmentDiagnostic {
  final int segmentIndex;
  final String anchorValue;
  final int startLine;
  final int endLine;
  final int lineCount;
  final String? localTextPreview;

  const SegmentDiagnostic({
    required this.segmentIndex,
    required this.anchorValue,
    required this.startLine,
    required this.endLine,
    required this.lineCount,
    this.localTextPreview,
  });

  factory SegmentDiagnostic.fromSegment(
    int index,
    CredentialTextSegment segment,
  ) => SegmentDiagnostic(
    segmentIndex: index,
    anchorValue: segment.anchor.value,
    startLine: segment.startLine,
    endLine: segment.endLine,
    lineCount: segment.endLine - segment.startLine,
    localTextPreview: DiagnosticValueFormatter.preview(segment.localText),
  );
}

class RuleTraceEntry {
  final String ruleId;
  final RecognitionField field;
  final RecognitionEvidenceKind kind;
  final int priority;
  final bool matched;
  final int candidateCount;
  final List<String> candidateValues;

  const RuleTraceEntry({
    required this.ruleId,
    required this.field,
    required this.kind,
    required this.priority,
    required this.matched,
    required this.candidateCount,
    required this.candidateValues,
  });
}

class CandidateDiagnostic {
  final RecognitionField field;
  final String ruleId;
  final int priority;
  final RecognitionEvidenceKind kind;
  final RecognitionEvidenceSource source;
  final bool isWinner;
  final bool isAlternative;
  final String normalizedValue;

  const CandidateDiagnostic({
    required this.field,
    required this.ruleId,
    required this.priority,
    required this.kind,
    required this.source,
    required this.isWinner,
    required this.isAlternative,
    required this.normalizedValue,
  });

  factory CandidateDiagnostic.fromCandidate(
    RecognitionCandidate candidate, {
    bool isWinner = false,
    bool isAlternative = false,
  }) => CandidateDiagnostic(
    field: candidate.field,
    ruleId: candidate.ruleId,
    priority: candidate.priority,
    kind: candidate.kind,
    source: candidate.source,
    isWinner: isWinner,
    isAlternative: isAlternative,
    normalizedValue: DiagnosticValueFormatter.value(
      candidate.field,
      candidate.value,
    ),
  );
}

class ConflictDiagnostic {
  final RecognitionField field;
  final CandidateDiagnostic winner;
  final int alternativeCount;
  final List<String> alternatives;

  const ConflictDiagnostic({
    required this.field,
    required this.winner,
    required this.alternativeCount,
    required this.alternatives,
  });

  factory ConflictDiagnostic.fromConflict(RecognitionConflict conflict) =>
      ConflictDiagnostic(
        field: conflict.field,
        winner: CandidateDiagnostic.fromCandidate(
          conflict.winner,
          isWinner: true,
        ),
        alternativeCount: conflict.alternatives.length,
        alternatives: [
          for (final c in conflict.alternatives)
            DiagnosticValueFormatter.value(conflict.field, c.value),
        ],
      );
}

class CredentialDiagnostic {
  final int credentialIndex;
  final String? anchorValue;
  final List<RuleTraceEntry> ruleTraces;
  final List<CandidateDiagnostic> candidates;
  final Map<RecognitionField, CandidateDiagnostic> winners;
  final List<ConflictDiagnostic> conflicts;
  final String trackingAssociation;
  final PickupCredentialSummary draft;

  const CredentialDiagnostic({
    required this.credentialIndex,
    required this.anchorValue,
    required this.ruleTraces,
    required this.candidates,
    required this.winners,
    required this.conflicts,
    required this.trackingAssociation,
    required this.draft,
  });
}

class PickupCredentialSummary {
  final CourierCompany courierCompany;
  final String? pickupCode;
  final String? trackingNumber;
  final PickupStatus status;
  final int conflictCount;

  const PickupCredentialSummary({
    required this.courierCompany,
    required this.pickupCode,
    required this.trackingNumber,
    required this.status,
    required this.conflictCount,
  });

  factory PickupCredentialSummary.fromDraft(PickupCredentialDraft draft) =>
      PickupCredentialSummary(
        courierCompany: draft.courierCompany,
        pickupCode: draft.pickupCode,
        trackingNumber: draft.trackingNumber == null
            ? null
            : DiagnosticValueFormatter.maskTracking(draft.trackingNumber!),
        status: draft.status,
        conflictCount: draft.conflicts.length,
      );
}

class DiagnosticValueFormatter {
  static String value(RecognitionField field, Object value) =>
      field == RecognitionField.trackingNumber
      ? maskTracking(value.toString())
      : value.toString();

  static String maskTracking(String value) {
    if (value.length <= 8) return '*' * value.length;
    return '${value.substring(0, 4)}${'*' * (value.length - 8)}${value.substring(value.length - 4)}';
  }

  static String preview(String text, {int maxLength = 100}) {
    final clean = text.replaceAll(RegExp(r'\b1[3-9]\d{9}\b'), '<PHONE>');
    final shortened = clean.length <= maxLength
        ? clean
        : '${clean.substring(0, maxLength)}…';
    return shortened;
  }
}

class RecognitionDiagnosticCollector {
  final int inputLength;
  final int rawLineCount;
  final String normalizedText;
  final List<RuleTraceEntry> _traces = [];
  final List<PickupAnchorDiagnostic> _anchors = [];
  final List<SegmentDiagnostic> _segments = [];
  final List<CredentialDiagnostic> _credentials = [];

  RecognitionDiagnosticCollector(
    this.inputLength,
    this.rawLineCount,
    this.normalizedText,
  );

  void recordAnchors(Iterable<PickupCodeAnchor> anchors) {
    final values = [...anchors];
    _anchors.addAll([
      for (var i = 0; i < values.length; i++)
        PickupAnchorDiagnostic.fromAnchor(i, values[i]),
    ]);
  }

  void recordSegments(Iterable<CredentialTextSegment> segments) {
    final values = [...segments];
    _segments.addAll([
      for (var i = 0; i < values.length; i++)
        SegmentDiagnostic.fromSegment(i, values[i]),
    ]);
  }

  List<RecognitionCandidate> evaluate(
    RecognitionRule rule,
    RecognitionContext context,
  ) {
    final candidates = rule.evaluate(context);
    _traces.add(
      RuleTraceEntry(
        ruleId: rule.id,
        field: rule.field,
        kind: rule.kind,
        priority: rule.priority,
        matched: candidates.isNotEmpty,
        candidateCount: candidates.length,
        candidateValues: [
          for (final c in candidates)
            DiagnosticValueFormatter.value(c.field, c.value),
        ],
      ),
    );
    return candidates;
  }

  void recordCredential(
    int index,
    String? anchor,
    List<RecognitionCandidate> candidates,
    Map<RecognitionField, RecognitionCandidate> winners,
    List<RecognitionConflict> conflicts,
    PickupCredentialDraft draft,
  ) {
    final alternativeValues = {
      for (final c in conflicts.expand((c) => c.alternatives)) c,
    };
    _credentials.add(
      CredentialDiagnostic(
        credentialIndex: index,
        anchorValue: anchor,
        ruleTraces: List.unmodifiable(_traces),
        candidates: [
          for (final c in candidates)
            CandidateDiagnostic.fromCandidate(
              c,
              isWinner: identical(winners[c.field], c),
              isAlternative: alternativeValues.contains(c),
            ),
        ],
        winners: {
          for (final e in winners.entries)
            e.key: CandidateDiagnostic.fromCandidate(e.value, isWinner: true),
        },
        conflicts: [
          for (final c in conflicts) ConflictDiagnostic.fromConflict(c),
        ],
        trackingAssociation: draft.trackingNumber == null ? 'none' : 'local',
        draft: PickupCredentialSummary.fromDraft(draft),
      ),
    );
    _traces.clear();
  }

  RecognitionDiagnosticReport build() => RecognitionDiagnosticReport(
    inputLength: inputLength,
    lineCount: rawLineCount,
    normalizedLength: normalizedText.length,
    normalizedLineCount: normalizedText.isEmpty
        ? 0
        : normalizedText.split('\n').length,
    anchors: List.unmodifiable(_anchors),
    segments: List.unmodifiable(_segments),
    credentials: List.unmodifiable(_credentials),
  );
}

class RecognitionDiagnosticFormatter {
  static String format(RecognitionDiagnosticReport report) {
    final out = StringBuffer(
      'Recognition\nInput:\n lines: ${report.normalizedLineCount}\n anchors: ${report.anchorCount}',
    );
    for (final credential in report.credentials) {
      out.write('\n\nCredential #${credential.credentialIndex + 1}');
      out.write('\n anchor: ${credential.anchorValue ?? 'none'}');
      final pickup = credential.winners[RecognitionField.pickupCode];
      if (pickup != null) out.write('\n pickup:\n   winner: ${pickup.ruleId}');
      out.write('\n courier: ${credential.draft.courierCompany.displayName}');
      out.write('\n tracking: ${credential.draft.trackingNumber ?? 'none'}');
      out.write('\n tracking_association: ${credential.trackingAssociation}');
      out.write('\n conflicts: ${credential.conflicts.length}');
    }
    return out.toString();
  }
}
