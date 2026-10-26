import 'package:doku/core/utils/date_utils.dart';
import 'package:doku/data/database/app_database.dart';
import 'package:doku/data/models/category.dart';
import 'package:sqflite/sqflite.dart';

class CategoryRepository {
  CategoryRepository([AppDatabase? database])
    : _db = database ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<List<Category>> all({TransactionType? type}) async {
    final db = await _db.database;
    final rows = await db.query(
      Tables.categories,
      where: type != null ? 'type = ?' : null,
      whereArgs: type != null ? [type.value] : null,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<int> count() async {
    final db = await _db.database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM ${Tables.categories}'),
        ) ??
        0;
  }

  /// Finds a category by name (case-insensitive) and type.
  Future<Category?> findByName(String name, TransactionType type) async {
    final db = await _db.database;
    final rows = await db.query(
      Tables.categories,
      where: 'name = ? COLLATE NOCASE AND type = ?',
      whereArgs: [name.trim(), type.value],
      orderBy: 'id ASC',
      limit: 1,
    );
    return rows.isEmpty ? null : Category.fromMap(rows.first);
  }

  Future<Category> create({
    required String name,
    String? description,
    required TransactionType type,
  }) async {
    final db = await _db.database;
    final now = Dates.timestamp();
    final category = Category(
      name: name.trim(),
      description: _clean(description),
      type: type,
      createdAt: now,
      updatedAt: now,
    );
    final id = await db.insert(Tables.categories, category.toMap());
    _db.notifyChanged();
    return Category.fromMap({...category.toMap(), 'id': id});
  }

  Future<void> update(Category category) async {
    final id = category.id;
    if (id == null) throw ArgumentError('Category has no id');
    final db = await _db.database;
    final updated = Category(
      id: id,
      name: category.name.trim(),
      description: _clean(category.description),
      type: category.type,
      createdAt: category.createdAt,
      updatedAt: Dates.timestamp(),
    );
    await db.update(
      Tables.categories,
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
    _db.notifyChanged();
  }

  /// Number of transactions that use the category.
  Future<int> usageCount(int categoryId) async {
    final db = await _db.database;
    return Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${Tables.transactions} WHERE category_id = ?',
            [categoryId],
          ),
        ) ??
        0;
  }

  /// Deletes a category together with its transactions, so no orphaned
  /// rows are left behind.
  Future<void> delete(int categoryId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete(
        Tables.transactions,
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );
      await txn.delete(
        Tables.categories,
        where: 'id = ?',
        whereArgs: [categoryId],
      );
    });
    _db.notifyChanged();
  }

  static String? _clean(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}
