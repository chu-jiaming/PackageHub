import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/core/parser/pickup_parser.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

class ExpectedCredential {
  final CourierCompany courierCompany;
  final String? pickupCode;
  final String? trackingNumber;
  final PickupStatus status;
  final List<String> ruleIds;

  const ExpectedCredential({
    required this.courierCompany,
    this.pickupCode,
    this.trackingNumber,
    this.status = PickupStatus.pending,
    this.ruleIds = const [],
  });
}

class RecognitionFixture {
  final String id;
  final String description;
  final String rawText;
  final List<ExpectedCredential> expectedCredentials;
  final int? expectedAnchorCount;
  final int? expectedConflictCount;

  const RecognitionFixture({
    required this.id,
    required this.description,
    required this.rawText,
    required this.expectedCredentials,
    this.expectedAnchorCount,
    this.expectedConflictCount,
  });
}

void expectRecognitionFixture(RecognitionFixture fixture) {
  final drafts = PickupParser.parseAll(fixture.rawText);
  expect(
    drafts,
    hasLength(fixture.expectedCredentials.length),
    reason: fixture.id,
  );
  for (var i = 0; i < drafts.length; i++) {
    final actual = drafts[i];
    final expected = fixture.expectedCredentials[i];
    expect(actual.courierCompany, expected.courierCompany, reason: fixture.id);
    expect(actual.pickupCode, expected.pickupCode, reason: fixture.id);
    expect(actual.trackingNumber, expected.trackingNumber, reason: fixture.id);
    expect(actual.status, expected.status, reason: fixture.id);
    for (final ruleId in expected.ruleIds) {
      expect(
        actual.evidence.map((e) => e.ruleId),
        contains(ruleId),
        reason: fixture.id,
      );
    }
  }
}

void expectDiagnosticFixture(RecognitionFixture fixture) {
  final result = PickupParser.parseAllWithDiagnostics(fixture.rawText);
  expect(
    result.drafts,
    hasLength(fixture.expectedCredentials.length),
    reason: fixture.id,
  );
  if (fixture.expectedAnchorCount != null) {
    expect(
      result.diagnostics.anchorCount,
      fixture.expectedAnchorCount,
      reason: fixture.id,
    );
  }
  if (fixture.expectedConflictCount != null) {
    expect(
      result.diagnostics.conflictCount,
      fixture.expectedConflictCount,
      reason: fixture.id,
    );
  }
}

/// Development-only helper for converting copied OCR into a reviewable fixture.
/// It intentionally leaves courier names and pickup-code-shaped values intact.
class RecognitionFixtureSanitizer {
  static String sanitize(String text) {
    var result = text.replaceAll(
      RegExp(r'(?<!\d)\+?86[ -]?1[3-9](?:[ -]?\d){9}(?!\d)'),
      '<PHONE>',
    );
    result = result.replaceAll(
      RegExp(r'(?<![A-Za-z0-9])\d{10,18}(?![A-Za-z0-9])'),
      '<TRACKING>',
    );
    return result;
  }
}
