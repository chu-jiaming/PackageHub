import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:packagehub/core/database/packagehub_database.dart';
import 'package:packagehub/core/repository/pickup_credential_repository.dart';
import 'package:packagehub/models/pickup_credential.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize FFI for desktop testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late PackageHubDatabase database;
  late PickupCredentialRepository repository;
  final temporaryDirectories = <Directory>[];
  final v1PendingCreatedAt = DateTime(2025, 1, 2, 3, 4, 5);
  final v1UnknownCreatedAt = DateTime(2025, 1, 3, 4, 5, 6);

  setUp(() async {
    database = PackageHubDatabase.instanceForTesting(
      dbFactory: () => openDatabase(
        inMemoryDatabasePath,
        version: packageHubDatabaseVersion,
        onCreate: createDatabaseSchema,
        onUpgrade: upgradeDatabaseSchema,
      ),
    );
    repository = PickupCredentialRepository(database);
  });

  tearDown(() async {
    await database.close();
    for (final directory in temporaryDirectories) {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
    temporaryDirectories.clear();
  });

  PickupCredentialDraft createDraft({
    CourierCompany courierCompany = CourierCompany.jtexpress,
    String? trackingNumber = 'JT123456789',
    String? pickupCode = '1-2-3',
    PickupStatus status = PickupStatus.pending,
    PackagePlatform sourcePlatform = PackagePlatform.pinduoduo,
    String rawText = '敏感信息 手机号 13800000000 地址 XXX',
    String? stationName = '菜鸟驿站',
  }) {
    return PickupCredentialDraft(
      courierCompany: courierCompany,
      trackingNumber: trackingNumber,
      pickupCode: pickupCode,
      stationName: stationName,
      status: status,
      sourcePlatform: sourcePlatform,
      rawText: rawText,
    );
  }

  Future<void> openMigratedV1Database() async {
    await database.close();

    final tempDir = await Directory.systemTemp.createTemp(
      'packagehub_v1_migration_',
    );
    temporaryDirectories.add(tempDir);
    final path = p.join(tempDir.path, 'packagehub.db');

    final v1Database = await openDatabase(
      path,
      version: 1,
      onCreate: createDatabaseSchema,
    );
    await v1Database.insert('pickup_credentials', {
      'courier_company': CourierCompany.jtexpress.name,
      'tracking_number': 'JT5519167631350',
      'pickup_code': 'Z5-2-1350',
      'status': PickupStatus.pending.name,
      'source_platform': PackagePlatform.pinduoduo.name,
      'created_at': v1PendingCreatedAt.millisecondsSinceEpoch,
      'updated_at': v1PendingCreatedAt.millisecondsSinceEpoch,
    });
    await v1Database.insert('pickup_credentials', {
      'courier_company': CourierCompany.sfExpress.name,
      'tracking_number': 'SF1234567890',
      'pickup_code': '3-28088',
      'status': PickupStatus.unknown.name,
      'source_platform': PackagePlatform.taobao.name,
      'created_at': v1UnknownCreatedAt.millisecondsSinceEpoch,
      'updated_at': v1UnknownCreatedAt.millisecondsSinceEpoch,
    });
    await v1Database.close();

    database = PackageHubDatabase.instanceForTesting(
      dbFactory: () => openDatabase(
        path,
        version: packageHubDatabaseVersion,
        onCreate: createDatabaseSchema,
        onUpgrade: upgradeDatabaseSchema,
      ),
    );
    repository = PickupCredentialRepository(database);
  }

  group('PickupCredentialRepository', () {
    test('Test 1: single insert returns entity with correct fields', () async {
      final draft = createDraft();
      final entity = await repository.insert(draft);

      expect(entity.id, isNotNull);
      expect(entity.courierCompany, CourierCompany.jtexpress);
      expect(entity.pickupCode, '1-2-3');
      expect(entity.trackingNumber, 'JT123456789');
      expect(entity.status, PickupStatus.pending);
      expect(entity.sourcePlatform, PackagePlatform.pinduoduo);
      expect(entity.createdAt, isNotNull);
      expect(entity.updatedAt, isNotNull);
    });

    test(
      'Test 2: insertAll 3 drafts returns 3 entities with count 3',
      () async {
        final drafts = [
          createDraft(courierCompany: CourierCompany.jtexpress),
          createDraft(courierCompany: CourierCompany.sfExpress),
          createDraft(courierCompany: CourierCompany.zto),
        ];

        final entities = await repository.insertAll(drafts);

        expect(entities.length, 3);
        expect(await repository.count(), 3);
      },
    );

    test('Test 3: getAll retrieves inserted data', () async {
      final draft = createDraft();
      await repository.insert(draft);

      final all = await repository.getAll();

      expect(all.length, 1);
      expect(all.first.courierCompany, CourierCompany.jtexpress);
      expect(all.first.pickupCode, '1-2-3');
    });

    test('Test 4: getById returns correct entity', () async {
      final draft = createDraft();
      final inserted = await repository.insert(draft);

      final found = await repository.getById(inserted.id!);

      expect(found, isNotNull);
      expect(found!.id, inserted.id);
      expect(found.courierCompany, CourierCompany.jtexpress);
    });

    test('Test 5: deleteById removes entity', () async {
      final draft = createDraft();
      final inserted = await repository.insert(draft);

      await repository.deleteById(inserted.id!);
      final found = await repository.getById(inserted.id!);

      expect(found, isNull);
    });

    test(
      'Test 6: null trackingNumber and pickupCode persist correctly',
      () async {
        final draft = createDraft(trackingNumber: null, pickupCode: null);
        final inserted = await repository.insert(draft);
        final found = await repository.getById(inserted.id!);

        expect(found, isNotNull);
        expect(found!.trackingNumber, isNull);
        expect(found.pickupCode, isNull);
      },
    );

    test('Test 7: unknown enum values round trip correctly', () async {
      final draft = createDraft(
        courierCompany: CourierCompany.unknown,
        status: PickupStatus.unknown,
        sourcePlatform: PackagePlatform.unknown,
      );
      final inserted = await repository.insert(draft);
      final found = await repository.getById(inserted.id!);

      expect(found, isNotNull);
      expect(found!.courierCompany, CourierCompany.unknown);
      expect(found.status, PickupStatus.unknown);
      expect(found.sourcePlatform, PackagePlatform.unknown);
    });

    test('pickedUp status serializes and reads back correctly', () async {
      final inserted = await repository.insert(
        createDraft(status: PickupStatus.pickedUp),
      );

      final found = await repository.getById(inserted.id!);

      expect(found, isNotNull);
      expect(found!.status, PickupStatus.pickedUp);
    });

    test(
      'Test 8: unknown courier string in database falls back to unknown',
      () async {
        final draft = createDraft();
        final inserted = await repository.insert(draft);

        // Manually corrupt the database value
        final db = await database.database;
        await db.update(
          'pickup_credentials',
          {'courier_company': 'nonexistent_courier'},
          where: 'id = ?',
          whereArgs: [inserted.id],
        );

        // Reading should not crash
        final found = await repository.getById(inserted.id!);

        expect(found, isNotNull);
        expect(found!.courierCompany, CourierCompany.unknown);
      },
    );

    test('unknown status string in database falls back to unknown', () async {
      final inserted = await repository.insert(createDraft());
      final db = await database.database;
      await db.update(
        'pickup_credentials',
        {'status': 'not_a_real_status'},
        where: 'id = ?',
        whereArgs: [inserted.id],
      );

      final found = await repository.getById(inserted.id!);

      expect(found, isNotNull);
      expect(found!.status, PickupStatus.unknown);
    });

    test('Test 9: rawText does not enter database schema', () async {
      final draft = createDraft(rawText: '手机号 13800000000 地址 XXX 订单号 123456');
      await repository.insert(draft);

      // Query raw database to verify no raw_text column
      final db = await database.database;
      final tableInfo = await db.rawQuery(
        "PRAGMA table_info(pickup_credentials)",
      );
      final columnNames = tableInfo
          .map((col) => col['name'] as String)
          .toList();

      expect(columnNames, isNot(contains('raw_text')));
      expect(columnNames, isNot(contains('rawText')));
      expect(columnNames, isNot(contains('image_path')));
      expect(columnNames, isNot(contains('image_bytes')));
    });

    test('Test 10: stationName does not enter database schema', () async {
      final draft = createDraft(stationName: '菜鸟驿站 XX小区店');
      await repository.insert(draft);

      // Query raw database to verify no station_name column
      final db = await database.database;
      final tableInfo = await db.rawQuery(
        "PRAGMA table_info(pickup_credentials)",
      );
      final columnNames = tableInfo
          .map((col) => col['name'] as String)
          .toList();

      expect(columnNames, isNot(contains('station_name')));
      expect(columnNames, isNot(contains('stationName')));
    });

    test(
      'Test 11: createdAt and updatedAt are consistent after save',
      () async {
        final before = DateTime.now();
        final draft = createDraft();
        final entity = await repository.insert(draft);
        final after = DateTime.now();

        // Timestamps should be within reasonable range
        expect(
          entity.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(
          entity.createdAt.isBefore(after.add(const Duration(seconds: 1))),
          isTrue,
        );
        expect(
          entity.updatedAt.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(
          entity.updatedAt.isBefore(after.add(const Duration(seconds: 1))),
          isTrue,
        );

        // Verify they survive round trip
        final found = await repository.getById(entity.id!);
        expect(found, isNotNull);
        expect(
          found!.createdAt.millisecondsSinceEpoch,
          entity.createdAt.millisecondsSinceEpoch,
        );
        expect(
          found.updatedAt.millisecondsSinceEpoch,
          entity.updatedAt.millisecondsSinceEpoch,
        );
      },
    );

    test('Test 12: insertAll assigns different ids to all items', () async {
      final drafts = [
        createDraft(courierCompany: CourierCompany.jtexpress),
        createDraft(courierCompany: CourierCompany.sfExpress),
        createDraft(courierCompany: CourierCompany.zto),
        createDraft(courierCompany: CourierCompany.sto),
        createDraft(courierCompany: CourierCompany.yunda),
      ];

      final entities = await repository.insertAll(drafts);

      final ids = entities.map((e) => e.id).toSet();
      expect(ids.length, 5, reason: 'All IDs should be unique');
      expect(entities.every((e) => e.id != null), isTrue);
    });

    test('update pickupCode succeeds', () async {
      final inserted = await repository.insert(createDraft());

      final updated = await repository.update(
        inserted.copyWith(pickupCode: 'Z5-2-1358'),
      );
      final found = await repository.getById(inserted.id!);

      expect(updated.pickupCode, 'Z5-2-1358');
      expect(found!.pickupCode, 'Z5-2-1358');
    });

    test('update courier succeeds', () async {
      final inserted = await repository.insert(createDraft());

      final updated = await repository.update(
        inserted.copyWith(courierCompany: CourierCompany.sfExpress),
      );
      final found = await repository.getById(inserted.id!);

      expect(updated.courierCompany, CourierCompany.sfExpress);
      expect(found!.courierCompany, CourierCompany.sfExpress);
    });

    test('update trackingNumber and sourcePlatform succeeds', () async {
      final inserted = await repository.insert(createDraft());

      final updated = await repository.update(
        inserted.copyWith(
          trackingNumber: 'SF1234567890',
          sourcePlatform: PackagePlatform.taobao,
        ),
      );
      final found = await repository.getById(inserted.id!);

      expect(updated.trackingNumber, 'SF1234567890');
      expect(updated.sourcePlatform, PackagePlatform.taobao);
      expect(found!.trackingNumber, 'SF1234567890');
      expect(found.sourcePlatform, PackagePlatform.taobao);
    });

    test('update status succeeds', () async {
      final inserted = await repository.insert(createDraft());

      final updated = await repository.update(
        inserted.copyWith(status: PickupStatus.pickedUp),
      );
      final found = await repository.getById(inserted.id!);

      expect(updated.status, PickupStatus.pickedUp);
      expect(found!.status, PickupStatus.pickedUp);
    });

    test('update keeps createdAt unchanged', () async {
      final inserted = await repository.insert(createDraft());
      final persistedBeforeUpdate = await repository.getById(inserted.id!);

      final updated = await repository.update(
        inserted.copyWith(pickupCode: 'Z5-2-1358', createdAt: DateTime(1999)),
      );
      final found = await repository.getById(inserted.id!);

      expect(
        updated.createdAt.millisecondsSinceEpoch,
        persistedBeforeUpdate!.createdAt.millisecondsSinceEpoch,
      );
      expect(
        found!.createdAt.millisecondsSinceEpoch,
        persistedBeforeUpdate.createdAt.millisecondsSinceEpoch,
      );
    });

    test('update refreshes updatedAt', () async {
      final inserted = await repository.insert(createDraft());
      final persistedBeforeUpdate = await repository.getById(inserted.id!);

      final updated = await repository.update(
        inserted.copyWith(pickupCode: 'Z5-2-1358'),
      );
      final found = await repository.getById(inserted.id!);

      expect(
        updated.updatedAt.millisecondsSinceEpoch,
        greaterThanOrEqualTo(
          persistedBeforeUpdate!.updatedAt.millisecondsSinceEpoch,
        ),
      );
      expect(
        found!.updatedAt.millisecondsSinceEpoch,
        greaterThanOrEqualTo(
          persistedBeforeUpdate.updatedAt.millisecondsSinceEpoch,
        ),
      );
    });

    test('update with null id throws ArgumentError', () async {
      final credential = PickupCredential.fromDraft(createDraft());

      expect(() => repository.update(credential), throwsArgumentError);
    });

    test('update with nonexistent id throws StateError', () async {
      final credential = PickupCredential.fromDraft(
        createDraft(),
        id: 99999,
        now: DateTime(2026),
      );

      expect(() => repository.update(credential), throwsStateError);
    });

    test('markPickedUp changes pending to pickedUp', () async {
      final inserted = await repository.insert(
        createDraft(status: PickupStatus.pending),
      );

      final updated = await repository.markPickedUp(inserted.id!);
      final found = await repository.getById(inserted.id!);

      expect(updated.status, PickupStatus.pickedUp);
      expect(found!.status, PickupStatus.pickedUp);
    });

    test('markPending changes pickedUp to pending', () async {
      final inserted = await repository.insert(
        createDraft(status: PickupStatus.pickedUp),
      );

      final updated = await repository.markPending(inserted.id!);
      final found = await repository.getById(inserted.id!);

      expect(updated.status, PickupStatus.pending);
      expect(found!.status, PickupStatus.pending);
    });

    test('markPickedUpAll 3 ids changes all to pickedUp', () async {
      final inserted = await repository.insertAll([
        createDraft(status: PickupStatus.pending),
        createDraft(status: PickupStatus.unknown),
        createDraft(status: PickupStatus.pending),
      ]);

      final updated = await repository.markPickedUpAll(
        inserted.map((credential) => credential.id!),
      );
      final all = await repository.getAll();

      expect(updated, hasLength(3));
      expect(
        updated.every(
          (credential) => credential.status == PickupStatus.pickedUp,
        ),
        isTrue,
      );
      expect(
        all.every((credential) => credential.status == PickupStatus.pickedUp),
        isTrue,
      );
    });

    test('markPendingAll mixed statuses changes all to pending', () async {
      final inserted = await repository.insertAll([
        createDraft(status: PickupStatus.pickedUp),
        createDraft(status: PickupStatus.unknown),
        createDraft(status: PickupStatus.pending),
      ]);

      final updated = await repository.markPendingAll(
        inserted.map((credential) => credential.id!),
      );
      final all = await repository.getAll();

      expect(updated, hasLength(3));
      expect(
        updated.every(
          (credential) => credential.status == PickupStatus.pending,
        ),
        isTrue,
      );
      expect(
        all.every((credential) => credential.status == PickupStatus.pending),
        isTrue,
      );
    });

    test('deleteAll 3 ids deletes all requested credentials', () async {
      final inserted = await repository.insertAll([
        createDraft(pickupCode: 'A'),
        createDraft(pickupCode: 'B'),
        createDraft(pickupCode: 'C'),
      ]);

      await repository.deleteAll(inserted.map((credential) => credential.id!));

      expect(await repository.count(), 0);
    });

    test('bulk empty ids are safe no-ops', () async {
      final inserted = await repository.insert(createDraft());

      expect(await repository.markPickedUpAll([]), isEmpty);
      expect(await repository.markPendingAll([]), isEmpty);
      await repository.deleteAll([]);

      expect(await repository.count(), 1);
      expect(await repository.getById(inserted.id!), isNotNull);
    });

    test('bulk duplicate ids are processed once', () async {
      final inserted = await repository.insertAll([
        createDraft(status: PickupStatus.pending),
        createDraft(status: PickupStatus.pending),
      ]);

      final updated = await repository.markPickedUpAll([
        inserted.first.id!,
        inserted.first.id!,
        inserted.last.id!,
        inserted.last.id!,
      ]);

      expect(updated, hasLength(2));
      expect(updated.map((credential) => credential.id), [
        inserted.first.id,
        inserted.last.id,
      ]);
      expect(
        (await repository.getAll()).every(
          (credential) => credential.status == PickupStatus.pickedUp,
        ),
        isTrue,
      );
    });

    test('bulk mark invalid id throws and rolls back transaction', () async {
      final inserted = await repository.insertAll([
        createDraft(status: PickupStatus.pending),
        createDraft(status: PickupStatus.pending),
      ]);

      expect(
        () => repository.markPickedUpAll([inserted.first.id!, 99999]),
        throwsStateError,
      );

      final all = await repository.getAll();
      expect(all, hasLength(2));
      expect(
        all.every((credential) => credential.status == PickupStatus.pending),
        isTrue,
      );
    });

    test('bulk delete invalid id throws and rolls back transaction', () async {
      final inserted = await repository.insertAll([
        createDraft(status: PickupStatus.pending),
        createDraft(status: PickupStatus.pickedUp),
      ]);

      expect(
        () => repository.deleteAll([inserted.first.id!, 99999]),
        throwsStateError,
      );

      expect(await repository.count(), 2);
      expect(await repository.getById(inserted.first.id!), isNotNull);
      expect(await repository.getById(inserted.last.id!), isNotNull);
    });

    test('bulk update keeps createdAt unchanged', () async {
      final inserted = await repository.insert(createDraft());
      final before = await repository.getById(inserted.id!);

      final updated = await repository.markPickedUpAll([inserted.id!]);
      final found = await repository.getById(inserted.id!);

      expect(
        updated.single.createdAt.millisecondsSinceEpoch,
        before!.createdAt.millisecondsSinceEpoch,
      );
      expect(
        found!.createdAt.millisecondsSinceEpoch,
        before.createdAt.millisecondsSinceEpoch,
      );
    });

    test('bulk update refreshes updatedAt', () async {
      final inserted = await repository.insert(createDraft());
      final before = await repository.getById(inserted.id!);
      await Future<void>.delayed(const Duration(milliseconds: 1));

      final updated = await repository.markPickedUpAll([inserted.id!]);
      final found = await repository.getById(inserted.id!);

      expect(
        updated.single.updatedAt.millisecondsSinceEpoch,
        greaterThan(before!.updatedAt.millisecondsSinceEpoch),
      );
      expect(
        found!.updatedAt.millisecondsSinceEpoch,
        greaterThan(before.updatedAt.millisecondsSinceEpoch),
      );
    });

    test('markPickedUp with nonexistent id throws StateError', () async {
      expect(() => repository.markPickedUp(99999), throwsStateError);
    });

    test('getPending only returns pending credentials', () async {
      await repository.insert(createDraft(status: PickupStatus.pending));
      await repository.insert(createDraft(status: PickupStatus.pickedUp));
      await repository.insert(createDraft(status: PickupStatus.unknown));

      final pending = await repository.getPending();

      expect(pending, hasLength(1));
      expect(pending.single.status, PickupStatus.pending);
    });

    test('getPickedUp only returns pickedUp credentials', () async {
      await repository.insert(createDraft(status: PickupStatus.pending));
      await repository.insert(createDraft(status: PickupStatus.pickedUp));
      await repository.insert(createDraft(status: PickupStatus.unknown));

      final pickedUp = await repository.getPickedUp();

      expect(pickedUp, hasLength(1));
      expect(pickedUp.single.status, PickupStatus.pickedUp);
    });

    test('findByTrackingNumber finds normalized tracking candidates', () async {
      await repository.insert(createDraft(trackingNumber: ' jt5519167631350 '));
      await repository.insert(createDraft(trackingNumber: 'SF1234567890'));

      final found = await repository.findByTrackingNumber('JT5519167631350');

      expect(found, hasLength(1));
      expect(found.single.trackingNumber, ' jt5519167631350 ');
    });

    test(
      'findByTrackingNumber ignores null and blank tracking numbers',
      () async {
        await repository.insert(createDraft(trackingNumber: null));
        await repository.insert(createDraft(trackingNumber: ''));

        expect(await repository.findByTrackingNumber(''), isEmpty);
        expect(
          await repository.findByTrackingNumber('JT5519167631350'),
          isEmpty,
        );
      },
    );

    test('unknown credentials do not enter getPending', () async {
      await repository.insert(createDraft(status: PickupStatus.unknown));

      final pending = await repository.getPending();

      expect(pending, isEmpty);
    });

    test('unknown credentials do not enter getPickedUp', () async {
      await repository.insert(createDraft(status: PickupStatus.unknown));

      final pickedUp = await repository.getPickedUp();

      expect(pickedUp, isEmpty);
    });

    test('v1 to v2 migration preserves existing data', () async {
      await openMigratedV1Database();
      final db = await database.database;

      final all = await repository.getAll();
      final pending = all.singleWhere(
        (credential) => credential.pickupCode == 'Z5-2-1350',
      );
      final unknown = all.singleWhere(
        (credential) => credential.pickupCode == '3-28088',
      );

      expect(await db.getVersion(), packageHubDatabaseVersion);
      expect(all, hasLength(2));
      expect(pending.courierCompany, CourierCompany.jtexpress);
      expect(pending.trackingNumber, 'JT5519167631350');
      expect(
        pending.createdAt.millisecondsSinceEpoch,
        v1PendingCreatedAt.millisecondsSinceEpoch,
      );
      expect(unknown.courierCompany, CourierCompany.sfExpress);
      expect(unknown.trackingNumber, 'SF1234567890');
      expect(
        unknown.createdAt.millisecondsSinceEpoch,
        v1UnknownCreatedAt.millisecondsSinceEpoch,
      );
    });

    test('migration reads old pending status correctly', () async {
      await openMigratedV1Database();

      final pending = await repository.getPending();

      expect(pending, hasLength(1));
      expect(pending.single.pickupCode, 'Z5-2-1350');
      expect(pending.single.status, PickupStatus.pending);
    });

    test('migration database can write pickedUp status', () async {
      await openMigratedV1Database();
      final pending = (await repository.getPending()).single;

      final updated = await repository.markPickedUp(pending.id!);
      final found = await repository.getById(pending.id!);

      expect(updated.status, PickupStatus.pickedUp);
      expect(found!.status, PickupStatus.pickedUp);
    });

    test('getAll returns empty list when no data', () async {
      final all = await repository.getAll();
      expect(all, isEmpty);
    });

    test('getById returns null for nonexistent id', () async {
      final found = await repository.getById(99999);
      expect(found, isNull);
    });

    test('count returns 0 for empty database', () async {
      expect(await repository.count(), 0);
    });
  });
}
