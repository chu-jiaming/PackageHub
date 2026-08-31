import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const int packageHubDatabaseVersion = 2;

/// Local SQLite database for PackageHub persistence.
///
/// PackageHub v1 local persistence deliberately stores only structured
/// pickup credential fields. Do not persist raw OCR text or imported
/// screenshots without an explicit future product decision.
class PackageHubDatabase {
  static PackageHubDatabase? _instance;

  final Future<Database> Function() _dbFactory;

  Database? _database;
  Future<Database>? _openingDatabase;

  PackageHubDatabase._(this._dbFactory);

  /// Singleton production instance backed by the real device filesystem.
  ///
  /// The database is lazily opened on first access and cached for the
  /// lifetime of the process.
  static PackageHubDatabase get instance {
    _instance ??= PackageHubDatabase._(_openProductionDatabase);
    return _instance!;
  }

  /// Create an instance with a custom database factory for testing.
  static PackageHubDatabase instanceForTesting({
    required Future<Database> Function() dbFactory,
  }) {
    return PackageHubDatabase._(dbFactory);
  }

  /// Get or open the database connection.
  ///
  /// The connection is opened lazily on first access and cached.
  /// Subsequent calls return the same open database.
  Future<Database> get database async {
    final cachedDatabase = _database;
    if (cachedDatabase != null && cachedDatabase.isOpen) {
      return cachedDatabase;
    }

    final openingDatabase = _openingDatabase;
    if (openingDatabase != null) {
      return openingDatabase;
    }

    final newOpeningDatabase = _dbFactory()
        .then((database) {
          _database = database;
          return database;
        })
        .whenComplete(() {
          _openingDatabase = null;
        });

    _openingDatabase = newOpeningDatabase;
    return newOpeningDatabase;
  }

  /// Close the database connection.
  ///
  /// Primarily for testing and future lifecycle management.
  /// Production code does not need to close after every query.
  Future<void> close() async {
    await _openingDatabase;
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

/// Open the real production database on the device filesystem.
Future<Database> _openProductionDatabase() async {
  final databasesPath = await getDatabasesPath();
  final path = join(databasesPath, 'packagehub.db');

  return openDatabase(
    path,
    version: packageHubDatabaseVersion,
    onCreate: createDatabaseSchema,
    onUpgrade: upgradeDatabaseSchema,
  );
}

/// Schema builder and migration handler.
///
/// Version 2 keeps the same columns as version 1 because status is already
/// stored as TEXT. The explicit migration path is still required so existing
/// user credentials are preserved when opening older databases.
Future<void> createDatabaseSchema(Database db, int version) async {
  await db.execute('''
    CREATE TABLE pickup_credentials (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      courier_company TEXT NOT NULL,
      tracking_number TEXT NULL,
      pickup_code TEXT NULL,
      status TEXT NOT NULL,
      source_platform TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
}

Future<void> upgradeDatabaseSchema(
  Database db,
  int oldVersion,
  int newVersion,
) async {
  if (oldVersion < 2 && newVersion >= 2) {
    await _migrateFromV1ToV2(db);
  }
}

Future<void> _migrateFromV1ToV2(Database db) async {
  // No schema changes are needed: pickup_credentials.status is already TEXT.
  // Keeping this as a real migration step verifies the v1 -> v2 path without
  // dropping or rebuilding user data.
}
