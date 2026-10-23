import 'package:doku/core/utils/date_utils.dart';
import 'package:doku/data/database/app_database.dart';
import 'package:doku/data/models/category.dart';
import 'package:doku/data/models/transaction.dart';
import 'package:sqflite/sqflite.dart';

/// Per-day totals, used to build charts.
class DailyTotal {
  const DailyTotal(this.date, this.income, this.expense);

  final DateTime date;
  final int income;
  final int expense;
}

class TransactionRepository {
  TransactionRepository([AppDatabase? database])
      : _db = database ?? AppDatabase.instance;

  final AppDatabase _db;

  static const _select = '''
    SELECT t.id, t.date, t.nominal, t.category_id, t.notes, t.created_at,
           t.updated_at, c.name AS category_name, c.type AS category_type,
           c.description AS category_description
    FROM ${Tables.transactions} t
    JOIN ${Tables.categories} c ON c.id = t.category_id
  ''';

  /// Builds a WHERE clause for an optional inclusive date range and type.
  static (String, List<Object?>) _where({
    String? start,
    String? end,
    TransactionType? type,
  }) {
    final clauses = <String>[];
    final args = <Object?>[];
    if (start != null) {
      clauses.add('t.date >= ?');
      args.add(start);
    }
    if (end != null) {
      clauses.add('t.date <= ?');
      args.add(end);
    }
    if (type != null) {
      clauses.add('c.type = ?');
      args.add(type.value);
    }
    return (clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}', args);
  }

  /// Transactions, newest first. Dates are `yyyy-MM-dd` (inclusive).
  Future<List<TransactionEntry>> list({
    String? start,
    String? end,
    TransactionType? type,
    int? limit,
    int offset = 0,
  }) async {
    final db = await _db.database;
    final (where, args) = _where(start: start, end: end, type: type);
    final paging = limit != null ? 'LIMIT ? OFFSET ?' : '';
    final rows = await db.rawQuery(
      '$_select $where ORDER BY t.date DESC, t.updated_at DESC, t.id DESC $paging',
      [...args, if (limit != null) ...[limit, offset]],
    );
    return rows.map(TransactionEntry.fromJoinedMap).toList();
  }

  Future<Summary> summary({String? start, String? end}) async {
    final db = await _db.database;
    final (where, args) = _where(start: start, end: end);
    final rows = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN c.type = 'income' THEN t.nominal ELSE 0 END), 0) AS income,
        COALESCE(SUM(CASE WHEN c.type = 'expense' THEN t.nominal ELSE 0 END), 0) AS expense
      FROM ${Tables.transactions} t
      JOIN ${Tables.categories} c ON c.id = t.category_id
      $where
    ''', args);
    final row = rows.first;
    return Summary(
      income: (row['income'] as num?)?.toInt() ?? 0,
      expense: (row['expense'] as num?)?.toInt() ?? 0,
    );
  }

  /// Totals per category for [type], largest first.
  Future<List<CategoryTotal>> totalsByCategory(
    TransactionType type, {
    String? start,
    String? end,
  }) async {
    final db = await _db.database;
    final (where, args) = _where(start: start, end: end, type: type);
    final rows = await db.rawQuery('''
      SELECT c.id AS id, c.name AS name, SUM(t.nominal) AS total
      FROM ${Tables.transactions} t
      JOIN ${Tables.categories} c ON c.id = t.category_id
      $where
      GROUP BY c.id
      ORDER BY total DESC
    ''', args);

    final totals = rows.map((r) => (r['total'] as num?)?.toInt() ?? 0).toList();
    final sum = totals.fold<int>(0, (a, b) => a + b);
    return [
      for (var i = 0; i < rows.length; i++)
        CategoryTotal(
          categoryId: (rows[i]['id'] as num).toInt(),
          name: (rows[i]['name'] as String?) ?? '',
          total: totals[i],
          share: sum == 0 ? 0 : totals[i] / sum,
        ),
    ];
  }

  /// Income/expense totals for each day that has transactions.
  Future<List<DailyTotal>> dailyTotals({String? start, String? end}) async {
    final db = await _db.database;
    final (where, args) = _where(start: start, end: end);
    final rows = await db.rawQuery('''
      SELECT t.date AS date,
        COALESCE(SUM(CASE WHEN c.type = 'income' THEN t.nominal ELSE 0 END), 0) AS income,
        COALESCE(SUM(CASE WHEN c.type = 'expense' THEN t.nominal ELSE 0 END), 0) AS expense
      FROM ${Tables.transactions} t
      JOIN ${Tables.categories} c ON c.id = t.category_id
      $where
      GROUP BY t.date
      ORDER BY t.date ASC
    ''', args);
    return [
      for (final row in rows)
        if (Dates.fromDb(row['date'] as String?) case final date?)
          DailyTotal(
            date,
            (row['income'] as num?)?.toInt() ?? 0,
            (row['expense'] as num?)?.toInt() ?? 0,
          ),
    ];
  }

  Future<int> create({
    required int nominal,
    required int categoryId,
    required DateTime date,
    String notes = '',
  }) async {
    final db = await _db.database;
    final now = Dates.timestamp();
    final id = await db.insert(
      Tables.transactions,
      TransactionEntry(
        nominal: nominal,
        categoryId: categoryId,
        date: Dates.toDb(date),
        notes: notes.trim(),
        createdAt: now,
        updatedAt: now,
      ).toMap(),
    );
    _db.notifyChanged();
    return id;
  }

  /// Inserts many rows atomically (used by Excel import).
  Future<void> createMany(List<TransactionEntry> entries) async {
    if (entries.isEmpty) return;
    final db = await _db.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final entry in entries) {
        batch.insert(Tables.transactions, entry.toMap());
      }
      await batch.commit(noResult: true);
    });
    _db.notifyChanged();
  }

  Future<void> update(
    int id, {
    required int nominal,
    required int categoryId,
    required DateTime date,
    String notes = '',
  }) async {
    final db = await _db.database;
    await db.update(
      Tables.transactions,
      {
        'nominal': nominal,
        'category_id': categoryId,
        'date': Dates.toDb(date),
        'notes': notes.trim(),
        'updated_at': Dates.timestamp(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _db.notifyChanged();
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete(Tables.transactions, where: 'id = ?', whereArgs: [id]);
    _db.notifyChanged();
  }

  Future<int> deleteOnDate(String date) async {
    final db = await _db.database;
    final count = await db
        .delete(Tables.transactions, where: 'date = ?', whereArgs: [date]);
    _db.notifyChanged();
    return count;
  }

  Future<int> count() async {
    final db = await _db.database;
    return Sqflite.firstIntValue(await db
            .rawQuery('SELECT COUNT(*) FROM ${Tables.transactions}')) ??
        0;
  }
}
