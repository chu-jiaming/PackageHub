import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/core/duplicate/pickup_duplicate_detector.dart';
import 'package:packagehub/core/duplicate/tracking_number_normalizer.dart';
import 'package:packagehub/core/repository/pickup_credential_repository.dart';
import 'package:packagehub/models/pickup_credential.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

void main() {
  group('normalizeTrackingNumber', () {
    test('matches ASCII case variants', () {
      expect(
        normalizeTrackingNumber('JT123'),
        normalizeTrackingNumber('jt123'),
      );
    });

    test('trims and removes ordinary spaces', () {
      expect(normalizeTrackingNumber(' JT123 '), 'JT123');
      expect(normalizeTrackingNumber('J T 1 2 3'), 'JT123');
    });

    test('null does not produce a duplicate key', () {
      expect(normalizeTrackingNumber(null), isNull);
    });

    test('blank string does not produce a duplicate key', () {
      expect(normalizeTrackingNumber('   '), isNull);
    });
  });

  group('PickupDuplicateDetector existing duplicates', () {
    test('same courier and same tracking is duplicate', () async {
      final result = await _check(
        existing: [_credential()],
        incoming: [_draft()],
      );

      expect(result.duplicates, hasLength(1));
      expect(result.duplicates.single.kind, DuplicateKind.existing);
    });

    test('same tracking with incoming unknown courier is duplicate', () async {
      final result = await _check(
        existing: [_credential(courierCompany: CourierCompany.jtexpress)],
        incoming: [_draft(courierCompany: CourierCompany.unknown)],
      );

      expect(result.duplicates, hasLength(1));
      expect(result.duplicates.single.kind, DuplicateKind.existing);
    });

    test('same tracking with existing unknown courier is duplicate', () async {
      final result = await _check(
        existing: [_credential(courierCompany: CourierCompany.unknown)],
        incoming: [_draft(courierCompany: CourierCompany.jtexpress)],
      );

      expect(result.duplicates, hasLength(1));
      expect(result.duplicates.single.kind, DuplicateKind.existing);
    });

    test(
      'same tracking with two different known couriers is not duplicate',
      () async {
        final result = await _check(
          existing: [_credential(courierCompany: CourierCompany.sfExpress)],
          incoming: [_draft(courierCompany: CourierCompany.jtexpress)],
        );

        expect(result.duplicates, isEmpty);
        expect(result.unique, hasLength(1));
      },
    );

    test('same pickupCode without tracking is not duplicate', () async {
      final result = await _check(
        existing: [_credential(trackingNumber: null, pickupCode: '3-2-105')],
        incoming: [_draft(trackingNumber: null, pickupCode: '3-2-105')],
      );

      expect(result.duplicates, isEmpty);
      expect(result.unique, hasLength(1));
    });

    test('pickedUp existing credential still counts as duplicate', () async {
      final result = await _check(
        existing: [_credential(status: PickupStatus.pickedUp)],
        incoming: [_draft()],
      );

      expect(result.duplicates, hasLength(1));
      expect(
        result.duplicates.single.existingCredential!.status,
        PickupStatus.pickedUp,
      );
    });

    test('tracking case and surrounding spaces are normalized', () async {
      final result = await _check(
        existing: [_credential(trackingNumber: ' jt5519167631350 ')],
        incoming: [_draft(trackingNumber: 'JT5519167631350')],
      );

      expect(result.duplicates, hasLength(1));
    });
  });

  group('PickupDuplicateDetector within batch duplicates', () {
    test('two drafts with same courier and tracking are duplicate', () async {
      final drafts = [_draft(pickupCode: 'A'), _draft(pickupCode: 'B')];

      final result = await _check(incoming: drafts);

      expect(result.duplicates, hasLength(1));
      expect(result.duplicates.single.kind, DuplicateKind.withinBatch);
      expect(result.duplicates.single.incomingIndex, 1);
      expect(result.duplicates.single.otherIncomingIndex, 0);
    });

    test(
      'three drafts with first and third duplicate create one conflict',
      () async {
        final drafts = [
          _draft(trackingNumber: 'JT123', pickupCode: 'A'),
          _draft(trackingNumber: 'SF123', pickupCode: 'B'),
          _draft(trackingNumber: ' jt123 ', pickupCode: 'C'),
        ];

        final result = await _check(incoming: drafts);

        expect(result.duplicates, hasLength(1));
        expect(result.duplicates.single.incomingIndex, 2);
        expect(result.duplicates.single.otherIncomingIndex, 0);
      },
    );

    test('different tracking numbers are not duplicates', () async {
      final result = await _check(
        incoming: [
          _draft(trackingNumber: 'JT123'),
          _draft(trackingNumber: 'JT456'),
        ],
      );

      expect(result.duplicates, isEmpty);
    });

    test('drafts without tracking numbers are not duplicates', () async {
      final result = await _check(
        incoming: [
          _draft(trackingNumber: null, pickupCode: '3-2-105'),
          _draft(trackingNumber: null, pickupCode: '3-2-105'),
        ],
      );

      expect(result.duplicates, isEmpty);
    });
  });
}

Future<DuplicateCheckResult> _check({
  List<PickupCredential> existing = const [],
  required List<PickupCredentialDraft> incoming,
}) {
  return PickupDuplicateDetector(
    repository: _FakePickupCredentialRepository(existing),
  ).check(incoming);
}

PickupCredentialDraft _draft({
  CourierCompany courierCompany = CourierCompany.jtexpress,
  String? trackingNumber = 'JT5519167631350',
  String? pickupCode = 'Z5-2-1350',
  PickupStatus status = PickupStatus.pending,
}) {
  return PickupCredentialDraft(
    courierCompany: courierCompany,
    trackingNumber: trackingNumber,
    pickupCode: pickupCode,
    stationName: '菜鸟驿站',
    status: status,
    sourcePlatform: PackagePlatform.pinduoduo,
    rawText: 'raw OCR text',
  );
}

PickupCredential _credential({
  int id = 1,
  CourierCompany courierCompany = CourierCompany.jtexpress,
  String? trackingNumber = 'JT5519167631350',
  String? pickupCode = 'Z5-2-1350',
  PickupStatus status = PickupStatus.pending,
}) {
  final now = DateTime(2026);
  return PickupCredential(
    id: id,
    courierCompany: courierCompany,
    trackingNumber: trackingNumber,
    pickupCode: pickupCode,
    status: status,
    sourcePlatform: PackagePlatform.pinduoduo,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakePickupCredentialRepository implements PickupCredentialRepositoryApi {
  final List<PickupCredential> credentials;

  const _FakePickupCredentialRepository(this.credentials);

  @override
  Future<List<PickupCredential>> findByTrackingNumber(
    String trackingNumber,
  ) async {
    final normalizedTrackingNumber = normalizeTrackingNumber(trackingNumber);
    return credentials
        .where(
          (credential) =>
              normalizeTrackingNumber(credential.trackingNumber) ==
              normalizedTrackingNumber,
        )
        .toList();
  }

  @override
  Future<void> deleteAll(Iterable<int> ids) async {}

  @override
  Future<void> deleteById(int id) async {}

  @override
  Future<List<PickupCredential>> getAll() async => credentials;

  @override
  Future<List<PickupCredential>> getPending() async => [];

  @override
  Future<List<PickupCredential>> getPickedUp() async => [];

  @override
  Future<List<PickupCredential>> insertAll(
    List<PickupCredentialDraft> drafts,
  ) async {
    return [];
  }

  @override
  Future<PickupCredential> markPending(int id) async {
    throw UnimplementedError();
  }

  @override
  Future<List<PickupCredential>> markPendingAll(Iterable<int> ids) async => [];

  @override
  Future<PickupCredential> markPickedUp(int id) async {
    throw UnimplementedError();
  }

  @override
  Future<List<PickupCredential>> markPickedUpAll(Iterable<int> ids) async => [];

  @override
  Future<PickupCredential> update(PickupCredential credential) async {
    throw UnimplementedError();
  }
}
