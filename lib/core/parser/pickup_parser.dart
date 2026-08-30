import 'package:packagehub/models/pickup_credential_draft.dart';

class PickupParser {
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

  static const List<String> _pendingKeywords = [
    '待取',
    '待领取',
    '请取件',
    '取件码',
    '凭取件码',
    '自提',
  ];

  static final RegExp _dashPattern = RegExp('[－–—−‐‑‒]');
  static final RegExp _spacePattern = RegExp(r'[ \t]+');
  static final RegExp _dashSpacingPattern = RegExp(r'\s*-\s*');
  static final RegExp _pipeSpacingPattern = RegExp(r'\s*\|\s*');
  static final RegExp _pickupCodePattern = RegExp(
    r'(?:取件码|取货码|提货码|自提码|身份码|开柜码)\s*[：:]?\s*([A-Za-z0-9]+(?:-[A-Za-z0-9]+)*)',
  );

  static PickupCredentialDraft parse(String rawText) {
    final normalizedText = normalizeText(rawText);
    final lines = normalizedText
        .split('\n')
        .where((line) => line.isNotEmpty)
        .toList();
    final pickupCodeResult = _parsePickupCode(lines);
    final pickupCode = pickupCodeResult?.code;

    return PickupCredentialDraft(
      platform: _parsePlatform(normalizedText),
      pickupCode: pickupCode,
      stationName: _parseStationName(lines, pickupCodeResult?.lineIndex),
      status: _parseStatus(normalizedText, pickupCode),
      rawText: normalizedText,
    );
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

  static _PickupCodeResult? _parsePickupCode(List<String> lines) {
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

      final normalizedCode = _normalizePickupCode(candidate);
      if (_isValidPickupCode(normalizedCode)) {
        return _PickupCodeResult(normalizedCode, i);
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

  static PickupStatus _parseStatus(String text, String? pickupCode) {
    if (pickupCode != null && _containsAny(text, _pendingKeywords)) {
      return PickupStatus.pending;
    }

    return PickupStatus.unknown;
  }

  static String _normalizePickupCode(String code) {
    final normalizedCode = code
        .trim()
        .replaceAll(_dashPattern, '-')
        .replaceAll(_dashSpacingPattern, '-');

    return normalizedCode
        .split('-')
        .map(_normalizeOcrZeroInCodeSegment)
        .join('-');
  }

  static String _normalizeOcrZeroInCodeSegment(String segment) {
    return segment.replaceFirstMapped(
      RegExp(r'^([A-Za-z])[Oo]$'),
      (match) => '${match.group(1)}0',
    );
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

  const _PickupCodeResult(this.code, this.lineIndex);
}
