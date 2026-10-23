import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Table and column names. These match the schema used since the first
/// release, so existing user data keeps working after an update.
abstract final class Tables {
  static const categories = 'categories';
  static const transactions = 'transactions';
}

/// Single, app-wide SQLite connection.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const _fileName = 'doku.db';
  static const _version = 2;

  /// Overridable in tests to use an in-memory database.
  @visibleForTesting
  static DatabaseFactory? factoryOverride;
  @visibleForTesting
  static String? pathOverride;

  Future<Database>? _opening;

  /// Increments after every write so screens can reload their data.
  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  Future<Database> get database async {
    try {
      return await (_opening ??= _open());
    } catch (_) {
      // Allow a later call to retry instead of caching the failure.
      _opening = null;
      rethrow;
    }
  }

  void notifyChanged() => changes.value++;

  Future<Database> _open() async {
    final path = pathOverride ??
        p.join((await getApplicationDocumentsDirectory()).path, _fileName);
    final factory = factoryOverride ?? databaseFactory;
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  @visibleForTesting
  Future<void> close() async {
    final db = await _opening;
    _opening = null;
    await db?.close();
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${Tables.categories} (
        id INTEGER PRIMARY KEY,
        name TEXT NULL,
        description TEXT NULL,
        type TEXT NULL,
        created_at TEXT NULL,
        updated_at TEXT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE ${Tables.transactions} (
        id INTEGER PRIMARY KEY,
        date TEXT NULL,
        nominal INTEGER NULL,
        category_id INTEGER NULL,
        notes TEXT NULL,
        created_at TEXT NULL,
        updated_at TEXT NULL
      )
    ''');
    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Older imports could store full ISO timestamps as the date; keep only
      // the `yyyy-MM-dd` part so range queries match them.
      await db.execute(
          'UPDATE ${Tables.transactions} SET date = substr(date, 1, 10) '
          'WHERE length(date) > 10');
      await _createIndexes(db);
    }
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_transactions_date ON ${Tables.transactions} (date)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_transactions_category ON ${Tables.transactions} (category_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_categories_type ON ${Tables.categories} (type)');
  }
}
