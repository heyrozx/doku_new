import 'dart:io';

import 'package:doku/data/database/app_database.dart';
import 'package:doku/data/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('upgrades a version 1 database without losing data', () async {
    sqfliteFfiInit();
    final dir = await Directory.systemTemp.createTemp('doku_migration');
    final path = p.join(dir.path, 'doku.db');

    // Schema and data exactly as written by the previous app release.
    final old = await databaseFactoryFfi.openDatabase(path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute(
                'CREATE TABLE categories (id INTEGER PRIMARY KEY, name TEXT NULL, description TEXT NULL, type TEXT NULL, created_at TEXT NULL, updated_at TEXT NULL)');
            await db.execute(
                'CREATE TABLE transactions (id INTEGER PRIMARY KEY, date TEXT NULL, nominal INTEGER NULL, category_id INTEGER NULL, notes TEXT NULL, created_at TEXT NULL, updated_at TEXT NULL)');
          },
        ));
    await old.insert('categories', {'id': 1, 'name': 'Makan', 'type': 'expense'});
    await old.insert('transactions',
        {'date': '2024-03-05', 'nominal': 1000, 'category_id': 1, 'notes': null});
    await old.insert('transactions', {
      'date': '2024-03-06T00:00:00.000Z',
      'nominal': 2000,
      'category_id': 1,
    });
    await old.close();

    AppDatabase.factoryOverride = databaseFactoryFfi;
    AppDatabase.pathOverride = path;
    await AppDatabase.instance.close();

    final repo = TransactionRepository();
    final march = await repo.list(start: '2024-03-01', end: '2024-03-31');
    expect(march.map((e) => e.date), ['2024-03-06', '2024-03-05']);
    expect(march.last.notes, '');
    expect((await repo.summary()).expense, 3000);

    await AppDatabase.instance.close();
    await dir.delete(recursive: true);
  });
}
