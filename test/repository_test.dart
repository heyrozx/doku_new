import 'dart:typed_data';

import 'package:doku/data/database/app_database.dart';
import 'package:doku/data/models/category.dart';
import 'package:doku/data/repositories/category_repository.dart';
import 'package:doku/data/repositories/transaction_repository.dart';
import 'package:doku/data/services/excel_service.dart';
import 'package:excel_community/excel_community.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late CategoryRepository categories;
  late TransactionRepository transactions;

  setUpAll(() {
    sqfliteFfiInit();
    AppDatabase.factoryOverride = databaseFactoryFfi;
    AppDatabase.pathOverride = inMemoryDatabasePath;
  });

  setUp(() async {
    await AppDatabase.instance.close();
    categories = CategoryRepository();
    transactions = TransactionRepository();
  });

  Future<(int, int)> seed() async {
    final salary = await categories.create(
        name: 'Gaji', type: TransactionType.income);
    final food = await categories.create(
        name: 'Makan', type: TransactionType.expense);
    await transactions.create(
        nominal: 5000000, categoryId: salary.id!, date: DateTime(2024, 5, 1));
    await transactions.create(
        nominal: 20000, categoryId: food.id!, date: DateTime(2024, 5, 31));
    await transactions.create(
        nominal: 30000,
        categoryId: food.id!,
        date: DateTime(2024, 6, 1),
        notes: ' siang ');
    return (salary.id!, food.id!);
  }

  test('summary respects inclusive date ranges', () async {
    await seed();
    final may = await transactions.summary(start: '2024-05-01', end: '2024-05-31');
    expect(may.income, 5000000);
    expect(may.expense, 20000);
    final all = await transactions.summary();
    expect(all.balance, 5000000 - 50000);
  });

  test('list is newest first, paginates and filters by type', () async {
    await seed();
    final all = await transactions.list();
    expect(all.map((e) => e.date), ['2024-06-01', '2024-05-31', '2024-05-01']);
    expect(all.first.notes, 'siang');
    expect(all.first.category?.name, 'Makan');

    final page2 = await transactions.list(limit: 2, offset: 2);
    expect(page2.single.date, '2024-05-01');

    final income = await transactions.list(type: TransactionType.income);
    expect(income.single.nominal, 5000000);
  });

  test('values with quotes are stored safely', () async {
    final c = await categories.create(
        name: 'Kopi "Enak"\'s', type: TransactionType.expense);
    expect(await categories.findByName('kopi "enak"\'s', TransactionType.expense),
        isNotNull);
    expect(c.name, 'Kopi "Enak"\'s');
  });

  test('totals by category and daily totals', () async {
    await seed();
    final expense = await transactions.totalsByCategory(TransactionType.expense);
    expect(expense.single.total, 50000);
    expect(expense.single.share, 1);

    final days = await transactions.dailyTotals(start: '2024-05-01', end: '2024-05-31');
    expect(days.length, 2);
  });

  test('deleting a category removes its transactions', () async {
    final (_, foodId) = await seed();
    expect(await categories.usageCount(foodId), 2);
    await categories.delete(foodId);
    expect(await transactions.count(), 1);
  });

  test('update and delete on date notify listeners', () async {
    await seed();
    var notified = 0;
    void listener() => notified++;
    AppDatabase.instance.changes.addListener(listener);
    final entry = (await transactions.list()).first;
    await transactions.update(entry.id!,
        nominal: 1, categoryId: entry.categoryId, date: entry.dateTime);
    expect((await transactions.list()).first.nominal, 1);
    expect(await transactions.deleteOnDate('2024-05-31'), 1);
    AppDatabase.instance.changes.removeListener(listener);
    expect(notified, 2);
  });

  test('excel export can be imported again', () async {
    await seed();
    final service = ExcelService();
    final bytes = service.buildWorkbook(await transactions.list());

    await AppDatabase.instance.close();
    final preview = service.parse(bytes);
    expect(preview.rows.length, 3);
    expect(preview.skipped, isEmpty);
    expect(await service.commit(preview.rows), 3);
    expect(await categories.count(), 2);
    expect((await transactions.summary()).balance, 5000000 - 50000);
  });

  test('excel import handles typed cells and skips invalid rows', () async {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!];
    sheet.appendRow([TextCellValue('Tanggal')]);
    sheet.appendRow([
      const DateCellValue(year: 2024, month: 2, day: 3),
      TextCellValue('catatan'),
      TextCellValue('Bonus'),
      TextCellValue('Pemasukan'),
      const DoubleCellValue(1500.0),
    ]);
    sheet.appendRow([
      TextCellValue('03/02/2024'),
      null,
      TextCellValue('Makan'),
      TextCellValue('expense'),
      TextCellValue('1.500'),
    ]);
    sheet.appendRow([
      TextCellValue('bukan tanggal'),
      null,
      TextCellValue('Makan'),
      TextCellValue('expense'),
      TextCellValue('10'),
    ]);
    final preview = ExcelService().parse(Uint8List.fromList(excel.save()!));
    expect(preview.rows.length, 2);
    expect(preview.rows[0].date, DateTime(2024, 2, 3));
    expect(preview.rows[0].type, TransactionType.income);
    expect(preview.rows[0].nominal, 1500);
    expect(preview.rows[1].nominal, 1500);
    expect(preview.skipped, ['4']);
  });
}
