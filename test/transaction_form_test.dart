import 'package:doku/data/database/app_database.dart';
import 'package:doku/data/models/category.dart';
import 'package:doku/data/repositories/category_repository.dart';
import 'package:doku/data/repositories/transaction_repository.dart';
import 'package:doku/features/transactions/transaction_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    AppDatabase.factoryOverride = databaseFactoryFfi;
    AppDatabase.pathOverride = inMemoryDatabasePath;
    await initializeDateFormatting('id');
  });

  testWidgets('saves a new expense from the form', (tester) async {
    await tester.runAsync(() async {
      await AppDatabase.instance.close();
      await CategoryRepository()
          .create(name: 'Makan', type: TransactionType.expense);
    });

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => TransactionFormScreen.open(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pump();

    // Category list loads from the database (real async I/O).
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'Makan'), findsOneWidget);

    // Saving without an amount shows a validation error.
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan jumlah lebih dari 0.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '25000');
    await tester.pump();
    expect(find.text('25.000'), findsOneWidget);

    await tester.tap(find.text('Simpan'));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();

    final saved = await tester.runAsync(() => TransactionRepository().list());
    expect(saved!.single.nominal, 25000);
    expect(saved.single.category?.name, 'Makan');
    expect(find.text('open'), findsOneWidget);
  });
}
