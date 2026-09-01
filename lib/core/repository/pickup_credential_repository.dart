import 'package:packagehub/core/database/packagehub_database.dart';
import 'package:packagehub/core/duplicate/tracking_number_normalizer.dart';
import 'package:packagehub/models/pickup_credential.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';
import 'package:packagehub/models/pickup_reminder_settings.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class PickupCredentialRepositoryApi {
  Future<List<PickupCredential>> insertAll(List<PickupCredentialDraft> drafts);

  Future<List<PickupCredential>> getAll();

  Future<List<PickupCredential>> getPending();

  Future<List<PickupCredential>> getPickedUp();

  Future<List<PickupCredential>> findByTrackingNumber(String trackingNumber);

  Future<PickupCredential> update(PickupCredential credential);

  Future<PickupCredential> markPickedUp(int id);

  Future<PickupCredential> markPending(int id);

  Future<void> deleteById(int id);

  Future<List<PickupCredential>> markPickedUpAll(Iterable<int> ids);

  Future<List<PickupCredential>> markPendingAll(Iterable<int> ids);

  Future<void> deleteAll(Iterable<int> ids);

}

/// Repository for managing pickup credential persistence.
///
/// PackageHub v1 local persistence deliberately stores only structured
/// pickup credential fields. Do not persist raw OCR text or imported
/// screenshots without an explicit future product decision.
class PickupCredentialRepository implements PickupCredentialRepositoryApi {
  final PackageHubDatabase _database;

  PickupCredentialRepository(this._database);

  static const _tableName = 'pickup_credentials';
  static const _settingsTableName = 'pickup_reminder_settings';

  Future<PickupReminderSettings> getReminderSettings() async {
    final db = await _database.database;
    final rows = await db.query(_settingsTableName, where: 'id = 1', limit: 1);
    if (rows.isEmpty) return const PickupReminderSettings();
    final row = rows.first;
    return PickupReminderSettings(
      enabled: row['enabled'] == 1,
      days: (row['days'] as int?)?.clamp(1, 30) ?? 3,
    );
  }

  Future<void> saveReminderSettings(PickupReminderSettings settings) async {
    final db = await _database.database;
    await db.insert(_settingsTableName, {
      'id': 1,
      'enabled': settings.enabled ? 1 : 0,
      'days': settings.days.clamp(1, 30),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Insert a single draft as a new credential.
  ///
  /// Returns the persisted entity with database-generated [id].
  Future<PickupCredential> insert(PickupCredentialDraft draft) async {
    final db = await _database.database;
    final entity = PickupCredential.fromDraft(draft);
    final id = await db.insert(_tableName, entity.toMap());
    return entity.copyWithId(id);
  }

  /// Insert multiple drafts in a single transaction.
  ///
  /// This is PackageHub's core workflow — confirming multiple credentials
  /// must be atomic. If any insert fails, the entire batch is rolled back.
  ///
  /// Returns all persisted entities with their database-generated IDs.
  @override
  Future<List<PickupCredential>> insertAll(
    List<PickupCredentialDraft> drafts,
  ) async {
    if (drafts.isEmpty) return [];

    final db = await _database.database;
    final now = DateTime.now();

    return await db.transaction((txn) async {
      final results = <PickupCredential>[];
      for (final draft in drafts) {
        final entity = PickupCredential.fromDraft(draft, now: now);
        final id = await txn.insert(_tableName, entity.toMap());
        results.add(entity.copyWithId(id));
      }
      return results;
    });
  }

  /// Retrieve all persisted credentials, ordered by creation time descending.
  @override
  Future<List<PickupCredential>> getAll() async {
    final db = await _database.database;
    final maps = await db.query(_tableName, orderBy: 'created_at DESC');
    return maps.map(PickupCredential.fromMap).toList();
  }

  @override
  Future<List<PickupCredential>> getPending() {
    return _getByStatus(PickupStatus.pending);
  }

  @override
  Future<List<PickupCredential>> getPickedUp() {
    return _getByStatus(PickupStatus.pickedUp);
  }

  Future<List<PickupCredential>> _getByStatus(PickupStatus status) async {
    final db = await _database.database;
    final maps = await db.query(
      _tableName,
      where: 'status = ?',
      whereArgs: [status.name],
      orderBy: 'created_at DESC',
    );
    return maps.map(PickupCredential.fromMap).toList();
  }

  @override
  Future<List<PickupCredential>> findByTrackingNumber(
    String trackingNumber,
  ) async {
    final normalizedTrackingNumber = normalizeTrackingNumber(trackingNumber);
    if (normalizedTrackingNumber == null) {
      return [];
    }

    final db = await _database.database;
    final maps = await db.query(
      _tableName,
      where: "tracking_number IS NOT NULL AND replace(upper(tracking_number), ' ', '') = ?",
      whereArgs: [normalizedTrackingNumber],
      orderBy: 'created_at DESC',
    );

    return maps
        .map(PickupCredential.fromMap)
        .where(
          (credential) =>
              normalizeTrackingNumber(credential.trackingNumber) ==
              normalizedTrackingNumber,
        )
        .toList();
  }

  /// Retrieve a single credential by its database [id].
  ///
  /// Returns `null` if no credential with the given ID exists.
  Future<PickupCredential?> getById(int id) async {
    final db = await _database.database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PickupCredential.fromMap(maps.first);
  }

  @override
  Future<PickupCredential> update(PickupCredential credential) async {
    final id = credential.id;
    if (id == null) {
      throw ArgumentError.value(
        credential.id,
        'credential.id',
        'Cannot update a pickup credential without an id.',
      );
    }

    final existing = await getById(id);
    if (existing == null) {
      throw StateError('No pickup credential exists for id $id.');
    }

    final updated = existing.copyWith(
      courierCompany: credential.courierCompany,
      trackingNumber: credential.trackingNumber,
      pickupCode: credential.pickupCode,
      status: credential.status,
      sourcePlatform: credential.sourcePlatform,
      updatedAt: DateTime.now(),
    );

    final db = await _database.database;
    final updatedRows = await db.update(
      _tableName,
      _toUpdateMap(updated),
      where: 'id = ?',
      whereArgs: [id],
    );
    if (updatedRows == 0) {
      throw StateError('No pickup credential exists for id $id.');
    }

    return updated;
  }

  @override
  Future<PickupCredential> markPickedUp(int id) async {
    final credential = await getById(id);
    if (credential == null) {
      throw StateError('No pickup credential exists for id $id.');
    }

    return update(credential.copyWith(status: PickupStatus.pickedUp));
  }

  @override
  Future<PickupCredential> markPending(int id) async {
    final credential = await getById(id);
    if (credential == null) {
      throw StateError('No pickup credential exists for id $id.');
    }

    return update(credential.copyWith(status: PickupStatus.pending));
  }

  @override
  Future<List<PickupCredential>> markPickedUpAll(Iterable<int> ids) {
    return _markStatusAll(ids, PickupStatus.pickedUp);
  }

  @override
  Future<List<PickupCredential>> markPendingAll(Iterable<int> ids) {
    return _markStatusAll(ids, PickupStatus.pending);
  }

  Future<List<PickupCredential>> _markStatusAll(
    Iterable<int> ids,
    PickupStatus status,
  ) async {
    final uniqueIds = _uniqueIds(ids);
    if (uniqueIds.isEmpty) return [];

    final db = await _database.database;
    final now = DateTime.now();

    return db.transaction((txn) async {
      final existingById = await _existingById(txn, uniqueIds);
      _requireAllIdsExist(uniqueIds, existingById);

      final placeholders = _placeholders(uniqueIds.length);
      await txn.update(
        _tableName,
        {'status': status.name, 'updated_at': now.millisecondsSinceEpoch},
        where: 'id IN ($placeholders)',
        whereArgs: uniqueIds,
      );

      return uniqueIds.map((id) {
        return existingById[id]!.copyWith(status: status, updatedAt: now);
      }).toList();
    });
  }

  /// Delete a credential by its database [id].
  @override
  Future<void> deleteById(int id) async {
    final db = await _database.database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteAll(Iterable<int> ids) async {
    final uniqueIds = _uniqueIds(ids);
    if (uniqueIds.isEmpty) return;

    final db = await _database.database;
    await db.transaction((txn) async {
      final existingById = await _existingById(txn, uniqueIds);
      _requireAllIdsExist(uniqueIds, existingById);

      final placeholders = _placeholders(uniqueIds.length);
      await txn.delete(
        _tableName,
        where: 'id IN ($placeholders)',
        whereArgs: uniqueIds,
      );
    });
  }

  /// Return the total number of persisted credentials.
  Future<int> count() async {
    final db = await _database.database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM $_tableName');
    return result.first['cnt'] as int;
  }

  Map<String, Object?> _toUpdateMap(PickupCredential credential) {
    return {
      'courier_company': credential.courierCompany.name,
      'tracking_number': credential.trackingNumber,
      'pickup_code': credential.pickupCode,
      'status': credential.status.name,
      'source_platform': credential.sourcePlatform.name,
      'updated_at': credential.updatedAt.millisecondsSinceEpoch,
    };
  }

  List<int> _uniqueIds(Iterable<int> ids) {
    return ids.toSet().toList(growable: false);
  }

  String _placeholders(int count) {
    return List.filled(count, '?').join(', ');
  }

  Future<Map<int, PickupCredential>> _existingById(
    DatabaseExecutor executor,
    List<int> ids,
  ) async {
    final placeholders = _placeholders(ids.length);
    final maps = await executor.query(
      _tableName,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    return {
      for (final credential in maps.map(PickupCredential.fromMap))
        credential.id!: credential,
    };
  }

  void _requireAllIdsExist(
    List<int> requestedIds,
    Map<int, PickupCredential> existingById,
  ) {
    for (final id in requestedIds) {
      if (!existingById.containsKey(id)) {
        throw StateError('No pickup credential exists for id $id.');
      }
    }
  }
}
