// Legacy helper methods remain below for compatibility with existing parser
// fixtures; recognition itself is now owned by the rule registry.
// ignore_for_file: unused_element

import 'package:packagehub/models/pickup_credential_draft.dart';
import 'package:packagehub/recognition/recognition_evidence.dart';
import 'package:packagehub/recognition/recognition_candidate.dart';
import 'package:packagehub/recognition/recognition_candidate_resolver.dart';
import 'package:packagehub/recognition/recognition_context.dart';
import 'package:packagehub/recognition/recognition_rule_registry.dart';
import 'package:packagehub/recognition/pickup_code_anchor.dart';
import 'package:packagehub/recognition/credential_segmenter.dart';
import 'package:packagehub/recognition/diagnostics/recognition_diagnostic_report.dart';

class RecognitionParseResult {
  final List<PickupCredentialDraft> drafts;
  final RecognitionDiagnosticReport diagnostics;

  const RecognitionParseResult({
    required this.drafts,
    required this.diagnostics,
  });
}

class PickupParser {
  static final RecognitionRuleRegistry ruleRegistry =
      RecognitionRuleRegistry.defaultRegistry();
  static const RecognitionCandidateResolver _resolver =
      RecognitionCandidateResolver();
  static const List<String> _pickupCodeKeywords = [
    '取件码',
    '取货码',
    '提货码',
    '自提码',
    '身份码',
    '开柜码',
  ];

  static const List<String> _stationKeywords = [
    '妈妈驿站',
    '菜鸟驿站',
    '快递超市',
    '代收点',
    '服务中心',
    '自提点',
    '快递柜',
    '丰巢',
    '兔喜',
    '驿站',
  ];

  static final List<_CourierPattern> _courierPatterns = [
    const _CourierPattern(CourierCompany.sfExpress, [
      '顺丰速运',
      '顺丰',
      'SF EXPRESS',
    ]),
    const _CourierPattern(CourierCompany.yto, ['圆通速递', '圆通']),
    const _CourierPattern(CourierCompany.zto, ['中通快递', '中通']),
    const _CourierPattern(CourierCompany.sto, ['申通快递', '申通']),
    const _CourierPattern(CourierCompany.yunda, ['韵达快递', '韵达']),
    const _CourierPattern(CourierCompany.jtexpress, [
      '极兔速递',
      '极兔',
      'J&T EXPRESS',
      'J&T',
    ]),
    const _CourierPattern(CourierCompany.ems, ['邮政EMS', 'EMS']),
    const _CourierPattern(CourierCompany.chinaPost, ['中国邮政', '邮政快递']),
    const _CourierPattern(CourierCompany.jdLogistics, ['京东物流', '京东快递']),
    const _CourierPattern(CourierCompany.deppon, ['德邦快递', '德邦']),
    const _CourierPattern(CourierCompany.cainiaoExpress, ['菜鸟速递']),
    const _CourierPattern(CourierCompany.bestExpress, ['百世快递', '百世']),
  ];

  static final RegExp _dashPattern = RegExp('[－–—−‐‑‒]');
  static final RegExp _spacePattern = RegExp(r'[ \t]+');
  static final RegExp _dashSpacingPattern = RegExp(r'\s*-\s*');
  static final RegExp _pipeSpacingPattern = RegExp(r'\s*\|\s*');
  static final RegExp _pickupCodePattern = RegExp(
    r'(?:取件码|取货码|提货码|自提码|身份码|开柜码)\s*(?:为|是)?\s*[：:]?\s*([A-Za-z0-9]+(?:\s*-[\s]*[A-Za-z0-9]+)*)',
  );
  static final RegExp _pickupCodeByCredentialPattern = RegExp(
    r'凭\s*[：:]?\s*([A-Za-z0-9]+(?:\s*-[\s]*\d+){2})(?=\s*(?:到|$))',
  );
  static final RegExp _trackingKeywordPattern = RegExp(
    r'(?:运单号|快递单号|物流单号)\s*[：:]?\s*([A-Za-z0-9]{8,30})',
  );
  static final RegExp _trackingCandidatePattern = RegExp(
    r'[A-Za-z]{1,4}\d[A-Za-z0-9]{7,25}|\d{10,18}',
  );
  static final RegExp _phoneNumberPattern = RegExp(r'^1[3-9]\d{9}$');
  static final RegExp _orderNumberContextPattern = RegExp(r'订单编号|订单号');
  static final RegExp _phoneContextPattern = RegExp(r'手机号|联系电话|电话');

  /// Legacy single-result convenience API. Production OCR uses [parseAll].
  /// It intentionally preserves Milestone 2 conflict semantics for compact
  /// text containing competing pickup-code candidates.
  static PickupCredentialDraft parse(String rawText) {
    return _parseContext(rawText, rawText);
  }

  static List<PickupCredentialDraft> parseAll(String rawText) {
    return _parseAll(rawText).drafts;
  }

  /// Runs the production parser once while collecting an in-memory,
  /// metadata-only trace for development and regression tests.
  static RecognitionParseResult parseAllWithDiagnostics(String rawText) {
    final normalizedText = normalizeText(rawText);
    final collector = RecognitionDiagnosticCollector(
      rawText.length,
      rawText.split(RegExp(r'\r?\n')).length,
      normalizedText,
    );
    final drafts = _parseAll(rawText, collector: collector).drafts;
    return RecognitionParseResult(
      drafts: drafts,
      diagnostics: collector.build(),
    );
  }

  static RecognitionParseResult _parseAll(
    String rawText, {
    RecognitionDiagnosticCollector? collector,
  }) {
    final normalizedText = normalizeText(rawText);
    final lines = normalizedText
        .split('\n')
        .where((line) => line.isNotEmpty)
        .toList();
    final context = RecognitionContext(
      rawText: rawText,
      normalizedText: normalizedText,
      lines: lines,
    );
    final directCandidates = [
      for (final rule in ruleRegistry.directRules) ...rule.evaluate(context),
    ];
    final pickupCandidates = directCandidates
        .where((candidate) => candidate.field == RecognitionField.pickupCode)
        .toList();
    final anchors = _discoverAnchors(normalizedText, pickupCandidates);
    collector?.recordAnchors(anchors);
    if (anchors.length < 2 || _isCompactConflict(anchors)) {
      if (anchors.isNotEmpty) {
        collector?.recordSegments(
          const CredentialSegmenter().segment(normalizedText, lines, anchors),
        );
      }
      final draft = _parseContext(
        rawText,
        normalizedText,
        collector: collector,
      );
      return RecognitionParseResult(
        drafts: [draft],
        diagnostics:
            collector?.build() ??
            const RecognitionDiagnosticReport(
              inputLength: 0,
              lineCount: 0,
              normalizedLength: 0,
              normalizedLineCount: 0,
              anchors: [],
              segments: [],
              credentials: [],
            ),
      );
    }
    final segments = const CredentialSegmenter().segment(
      normalizedText,
      lines,
      anchors,
    );
    collector?.recordSegments(segments);
    final uniqueCourierCandidates = directCandidates
        .where(
          (candidate) => candidate.field == RecognitionField.courierCompany,
        )
        .map((candidate) => candidate.value as CourierCompany)
        .toSet();
    final hasAppCardAnchors = pickupCandidates.any(
      (candidate) => candidate.ruleId == 'pickup_code.app_card_context',
    );
    final sharedCourier =
        !hasAppCardAnchors && uniqueCourierCandidates.length == 1
        ? uniqueCourierCandidates.single
        : null;
    final sharedCourierCandidate = sharedCourier == null
        ? null
        : directCandidates.firstWhere(
            (candidate) => candidate.field == RecognitionField.courierCompany,
          );
    final sharedPlatform = _parsePlatform(normalizedText);
    final drafts = [
      for (var i = 0; i < segments.length; i++)
        _parseContext(
          rawText,
          segments[i].localText,
          diagnosticIndex: i,
          diagnosticAnchor: segments[i].anchor.value,
          collector: collector,
          forcedPickup: segments[i].anchor.candidate,
          sharedCourier: sharedCourier,
          sharedCourierCandidate: sharedCourierCandidate,
          sharedPlatform: sharedPlatform,
        ),
    ];
    return RecognitionParseResult(
      drafts: drafts,
      diagnostics:
          collector?.build() ??
          const RecognitionDiagnosticReport(
            inputLength: 0,
            lineCount: 0,
            normalizedLength: 0,
            normalizedLineCount: 0,
            anchors: [],
            segments: [],
            credentials: [],
          ),
    );
  }

  static PickupCredentialDraft _parseContext(
    String rawText,
    String text, {
    RecognitionCandidate? forcedPickup,
    CourierCompany? sharedCourier,
    RecognitionCandidate? sharedCourierCandidate,
    PackagePlatform? sharedPlatform,
    RecognitionDiagnosticCollector? collector,
    int? diagnosticIndex,
    String? diagnosticAnchor,
  }) {
    final normalizedText = normalizeText(text);
    final lines = normalizedText
        .split('\n')
        .where((line) => line.isNotEmpty)
        .toList();
    final context = RecognitionContext(
      rawText: rawText,
      normalizedText: normalizedText,
      lines: lines,
    );
    final directCandidates = [
      for (final rule in ruleRegistry.directRules)
        ...(collector?.evaluate(rule, context) ?? rule.evaluate(context)),
    ];
    final forcedCandidates = forcedPickup == null
        ? const <RecognitionCandidate>[]
        : [forcedPickup];
    final scopedCandidates = forcedPickup == null
        ? directCandidates
        : [
            ...forcedCandidates,
            ...directCandidates.where(
              (candidate) =>
                  candidate.field != RecognitionField.pickupCode &&
                  (candidate.field != RecognitionField.trackingNumber ||
                      _candidateOffset(normalizedText, candidate) >=
                          _candidateOffset(normalizedText, forcedPickup)),
            ),
          ];
    final directResolution = _resolver.resolve(scopedCandidates);
    final pickupCandidate =
        directResolution.winners[RecognitionField.pickupCode];
    final directCourier =
        directResolution.winners[RecognitionField.courierCompany];
    final inferenceCandidates = directCourier == null && sharedCourier == null
        ? [
            for (final rule in ruleRegistry.inferenceRules)
              ...(collector?.evaluate(
                    rule,
                    RecognitionContext(
                      rawText: rawText,
                      normalizedText: normalizedText,
                      lines: lines,
                      currentPickupCode: pickupCandidate?.value as String?,
                    ),
                  ) ??
                  rule.evaluate(
                    RecognitionContext(
                      rawText: rawText,
                      normalizedText: normalizedText,
                      lines: lines,
                      currentPickupCode: pickupCandidate?.value as String?,
                    ),
                  )),
          ]
        : const <RecognitionCandidate>[];
    final inferenceResolution = _resolver.resolve(inferenceCandidates);
    final allWinners = {
      ...directResolution.winners,
      ...inferenceResolution.winners,
    };
    if (directCourier == null && sharedCourierCandidate != null) {
      allWinners[RecognitionField.courierCompany] = sharedCourierCandidate;
    }
    final evidence = [
      for (final candidate in allWinners.values) candidate.toEvidence(),
    ];
    final pickupCode = pickupCandidate?.value as String?;
    final courierCompany =
        (directCourier?.value ??
                sharedCourier ??
                inferenceResolution
                    .winners[RecognitionField.courierCompany]
                    ?.value ??
                CourierCompany.unknown)
            as CourierCompany;
    final trackingNumber =
        allWinners[RecognitionField.trackingNumber]?.value as String?;
    final draft = PickupCredentialDraft(
      courierCompany: courierCompany,
      trackingNumber: trackingNumber,
      pickupCode: pickupCode,
      stationName: _parseStationName(
        lines,
        pickupCandidate?.matchedText == null
            ? null
            : _lineIndexAt(
                normalizedText,
                normalizedText.indexOf(pickupCandidate!.matchedText!),
              ),
      ),
      // A logistics status in OCR cannot prove that the user collected the
      // parcel. New credentials always enter PackageHub as pending.
      status: PickupStatus.pending,
      sourcePlatform: sharedPlatform ?? _parsePlatform(normalizedText),
      rawText: normalizedText,
      evidence: evidence,
      conflicts: [
        ...directResolution.conflicts,
        ...inferenceResolution.conflicts,
      ],
    );
    collector?.recordCredential(
      diagnosticIndex ?? 0,
      diagnosticAnchor,
      [...directCandidates, ...inferenceCandidates],
      allWinners,
      [...directResolution.conflicts, ...inferenceResolution.conflicts],
      draft,
    );
    return draft;
  }

  static List<PickupCodeAnchor> _discoverAnchors(
    String text,
    List<RecognitionCandidate> candidates,
  ) {
    final result = <PickupCodeAnchor>[];
    final usedValues = <String>{};
    final cursors = <String, int>{};
    for (final candidate in candidates) {
      final value = candidate.value as String;
      if (!usedValues.add(value)) continue;
      final matched = candidate.matchedText ?? value;
      final cursor = cursors[matched] ?? 0;
      final found = text.indexOf(matched, cursor);
      final start = found < 0 ? text.indexOf(value) : found;
      if (start < 0) continue;
      cursors[matched] = start + matched.length;
      result.add(
        PickupCodeAnchor(
          value: value,
          startOffset: start,
          endOffset: start + matched.length,
          lineIndex: _lineIndexAt(text, start),
          ruleId: candidate.ruleId,
          priority: candidate.priority,
          matchedText: candidate.matchedText,
          candidate: candidate,
        ),
      );
    }
    result.sort((a, b) => a.startOffset.compareTo(b.startOffset));
    return result;
  }

  static int _candidateOffset(String text, RecognitionCandidate candidate) {
    final matched = candidate.matchedText;
    if (matched == null) return text.length;
    return text.indexOf(matched);
  }

  static bool _isCompactConflict(List<PickupCodeAnchor> anchors) {
    if (anchors.length < 2) return false;
    for (var i = 1; i < anchors.length; i++) {
      final previous = anchors[i - 1];
      final current = anchors[i];
      if (previous.lineIndex != current.lineIndex) return false;
      if (current.startOffset - previous.endOffset > 24) return false;
    }
    return true;
  }

  static String normalizeText(String rawText) {
    return rawText
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(_dashPattern, '-')
        .split('\n')
        .map((line) {
          return line
              .trim()
              .replaceAll(_spacePattern, ' ')
              .replaceAll(_dashSpacingPattern, '-');
        })
        .where((line) => line.isNotEmpty)
        .join('\n')
        .trim();
  }

  static PackagePlatform _parsePlatform(String text) {
    if (text.contains('拼多多')) {
      return PackagePlatform.pinduoduo;
    }

    if (text.contains('淘宝') || text.contains('天猫') || text.contains('淘特')) {
      return PackagePlatform.taobao;
    }

    if (text.contains('京东')) {
      return PackagePlatform.jd;
    }

    if (text.contains('菜鸟')) {
      return PackagePlatform.cainiao;
    }

    return PackagePlatform.unknown;
  }

  static _PickupCodeResult? _parsePickupCode(
    String normalizedText,
    List<String> lines,
  ) {
    final explicitMatch = _pickupCodePattern.firstMatch(normalizedText);
    final explicitCode = explicitMatch?.group(1);
    if (explicitCode != null) {
      final normalizedCode = normalizePickupCode(explicitCode);
      if (_isValidPickupCode(normalizedCode)) {
        return _PickupCodeResult(
          normalizedCode,
          _lineIndexAt(normalizedText, explicitMatch!.start),
          ruleId: 'pickup_code.explicit_keyword',
          matchedText: explicitMatch.group(0),
        );
      }
    }

    final credentialMatch = _pickupCodeByCredentialPattern.firstMatch(
      normalizedText,
    );
    final credentialCode = credentialMatch?.group(1);
    if (credentialCode != null) {
      final normalizedCode = normalizePickupCode(credentialCode);
      if (_isValidPickupCode(normalizedCode)) {
        return _PickupCodeResult(
          normalizedCode,
          _lineIndexAt(normalizedText, credentialMatch!.start),
          ruleId: 'pickup_code.after_ping',
          matchedText: credentialMatch.group(0),
        );
      }
    }

    for (var i = 0; i < lines.length; i += 1) {
      final line = lines[i];
      if (!_containsAny(line, _pickupCodeKeywords)) {
        continue;
      }

      final match = _pickupCodePattern.firstMatch(line);
      if (match == null) {
        continue;
      }

      final candidate = match.group(1);
      if (candidate == null) {
        continue;
      }

      final normalizedCode = normalizePickupCode(candidate);
      if (_isValidPickupCode(normalizedCode)) {
        return _PickupCodeResult(
          normalizedCode,
          i,
          ruleId: 'pickup_code.explicit_keyword',
          matchedText: match.group(0),
        );
      }
    }

    return null;
  }

  static int _lineIndexAt(String text, int offset) {
    return '\n'.allMatches(text.substring(0, offset)).length;
  }

  static _CourierResult? _parseCourierCompany(List<String> lines) {
    for (var i = 0; i < lines.length; i += 1) {
      final line = lines[i];
      for (final pattern in _courierPatterns) {
        final matchedKeyword = pattern.matchKeyword(line);
        if (matchedKeyword != null) {
          return _CourierResult(pattern.company, i, matchedKeyword);
        }
      }
    }

    return null;
  }

  static String? _parseTrackingNumber(
    List<String> lines,
    _CourierResult? courierResult,
  ) {
    if (courierResult != null) {
      final sameLineTrackingNumber = _extractTrackingNumber(
        lines[courierResult.lineIndex],
        courierKeyword: courierResult.matchedKeyword,
        allowWithoutKeyword: true,
      );
      if (sameLineTrackingNumber != null) {
        return sameLineTrackingNumber;
      }

      final nearbyTrackingNumber = _parseNearbyTrackingNumber(
        lines,
        courierResult.lineIndex,
      );
      if (nearbyTrackingNumber != null) {
        return nearbyTrackingNumber;
      }
    }

    for (final line in lines) {
      final trackingNumber = _extractTrackingNumber(line);
      if (trackingNumber != null) {
        return trackingNumber;
      }
    }

    return null;
  }

  static String? _parseNearbyTrackingNumber(
    List<String> lines,
    int courierLineIndex,
  ) {
    for (final offset in [1, -1, 2, -2]) {
      final index = courierLineIndex + offset;
      if (index < 0 || index >= lines.length) {
        continue;
      }

      final trackingNumber = _extractTrackingNumber(
        lines[index],
        allowWithoutKeyword: true,
      );
      if (trackingNumber != null) {
        return trackingNumber;
      }
    }

    return null;
  }

  static String? _parseStationName(
    List<String> lines,
    int? pickupCodeLineIndex,
  ) {
    final orderedIndices = <int>[];

    if (pickupCodeLineIndex != null) {
      for (final offset in [1, -1, 2, -2, 0, 3, -3]) {
        final index = pickupCodeLineIndex + offset;
        if (index >= 0 &&
            index < lines.length &&
            !orderedIndices.contains(index)) {
          orderedIndices.add(index);
        }
      }
    }

    for (var i = 0; i < lines.length; i += 1) {
      if (!orderedIndices.contains(i)) {
        orderedIndices.add(i);
      }
    }

    for (final index in orderedIndices) {
      final line = lines[index];
      if (_containsAny(line, _stationKeywords)) {
        return _cleanStationName(line);
      }
    }

    return null;
  }

  static String? _extractTrackingNumber(
    String line, {
    String? courierKeyword,
    bool allowWithoutKeyword = false,
  }) {
    if (_orderNumberContextPattern.hasMatch(line)) {
      return null;
    }

    if (_phoneContextPattern.hasMatch(line)) {
      return null;
    }

    final keywordMatch = _trackingKeywordPattern.firstMatch(line);
    if (keywordMatch != null) {
      return _validTrackingNumberOrNull(keywordMatch.group(1));
    }

    if (!allowWithoutKeyword) {
      return null;
    }

    final searchableText = courierKeyword == null
        ? line
        : line.replaceFirst(courierKeyword, ' ');

    for (final match in _trackingCandidatePattern.allMatches(searchableText)) {
      final candidate = _validTrackingNumberOrNull(match.group(0));
      if (candidate != null) {
        return candidate;
      }
    }

    return null;
  }

  static String? _validTrackingNumberOrNull(String? candidate) {
    if (candidate == null) {
      return null;
    }

    final trackingNumber = candidate.trim();
    if (trackingNumber.isEmpty ||
        _phoneNumberPattern.hasMatch(trackingNumber)) {
      return null;
    }

    return trackingNumber;
  }

  static String normalizePickupCode(String code) {
    final normalizedCode = code
        .trim()
        .replaceAll(_dashPattern, '-')
        .replaceAll(_dashSpacingPattern, '-');

    return normalizedCode.split('-').join('-');
  }

  static bool _isValidPickupCode(String code) {
    if (code.length < 3 || code.length > 14) {
      return false;
    }

    if (!RegExp(r'^[A-Za-z0-9]+(?:-[A-Za-z0-9]+)*$').hasMatch(code)) {
      return false;
    }

    if (!RegExp(r'\d').hasMatch(code)) {
      return false;
    }

    final compactCode = code.replaceAll('-', '');
    if (RegExp(r'^1\d{10}$').hasMatch(compactCode)) {
      return false;
    }

    return true;
  }

  static String _cleanStationName(String line) {
    return line
        .trim()
        .replaceAll(_spacePattern, ' ')
        .replaceAll(_pipeSpacingPattern, ' | ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }
}

class _PickupCodeResult {
  final String code;
  final int lineIndex;
  final String ruleId;
  final String? matchedText;

  const _PickupCodeResult(
    this.code,
    this.lineIndex, {
    required this.ruleId,
    this.matchedText,
  });
}

class _CourierPattern {
  final CourierCompany company;
  final List<String> keywords;

  const _CourierPattern(this.company, this.keywords);

  String? matchKeyword(String text) {
    final normalizedText = text.toUpperCase();

    for (final keyword in keywords) {
      if (normalizedText.contains(keyword.toUpperCase())) {
        return keyword;
      }
    }

    return null;
  }
}

class _CourierResult {
  final CourierCompany company;
  final int lineIndex;
  final String matchedKeyword;

  String get matchedText => matchedKeyword;

  const _CourierResult(this.company, this.lineIndex, this.matchedKeyword);
}
