import 'dart:typed_data';

import 'package:doku/core/utils/date_utils.dart';
import 'package:doku/core/utils/formatters.dart';
import 'package:doku/data/models/category.dart';
import 'package:doku/data/models/transaction.dart';
import 'package:doku/data/repositories/category_repository.dart';
import 'package:doku/data/repositories/transaction_repository.dart';
import 'package:excel_community/excel_community.dart';
import 'package:intl/intl.dart';

/// A row parsed from an Excel file, before categories are resolved.
class ImportRow {
  const ImportRow({
    required this.date,
    required this.notes,
    required this.categoryName,
    required this.type,
    required this.nominal,
  });

  final DateTime date;
  final String notes;
  final String categoryName;
  final TransactionType type;
  final int nominal;
}

class ImportPreview {
  const ImportPreview(this.rows, this.skipped);

  final List<ImportRow> rows;

  /// 1-based row numbers (per sheet) that could not be read.
  final List<String> skipped;
}

/// Reads and writes the `.xlsx` format used by DOKU.
///
/// Columns: Tanggal | Keterangan | Kategori | Jenis | Nominal
class ExcelService {
  ExcelService({
    CategoryRepository? categories,
    TransactionRepository? transactions,
  })  : _categories = categories ?? CategoryRepository(),
        _transactions = transactions ?? TransactionRepository();

  final CategoryRepository _categories;
  final TransactionRepository _transactions;

  static const mimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  static const headers = ['Tanggal', 'Keterangan', 'Kategori', 'Jenis', 'Nominal'];

  /// Builds an `.xlsx` workbook from [entries].
  Uint8List buildWorkbook(List<TransactionEntry> entries) {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
    final sheet = excel[sheetName];

    sheet.appendRow([for (final h in headers) TextCellValue(h)]);
    for (final e in entries) {
      sheet.appendRow([
        TextCellValue(e.date),
        TextCellValue(e.notes),
        TextCellValue(e.category?.name ?? ''),
        TextCellValue(e.type.value),
        IntCellValue(e.nominal),
      ]);
    }

    final bytes = excel.save(fileName: 'doku.xlsx');
    if (bytes == null) throw StateError('Gagal membuat file Excel.');
    return Uint8List.fromList(bytes);
  }

  /// Parses an `.xlsx` file. Header rows and invalid rows are skipped.
  ImportPreview parse(Uint8List bytes) {
    final Excel excel;
    try {
      excel = Excel.decodeBytes(bytes);
    } catch (_) {
      throw const FormatException('File bukan Excel (.xlsx) yang valid.');
    }

    final rows = <ImportRow>[];
    final skipped = <String>[];
    for (final entry in excel.tables.entries) {
      final sheetRows = entry.value.rows;
      for (var i = 0; i < sheetRows.length; i++) {
        final cells = sheetRows[i];
        if (cells.every((c) => _text(c?.value).isEmpty)) continue;

        final row = _parseRow(cells);
        if (row != null) {
          rows.add(row);
        } else if (!_isHeader(cells)) {
          skipped.add(excel.tables.length > 1 ? '${entry.key}:${i + 1}' : '${i + 1}');
        }
      }
    }
    return ImportPreview(rows, skipped);
  }

  /// Saves parsed rows, creating any missing categories. Returns the number
  /// of imported transactions.
  Future<int> commit(List<ImportRow> rows) async {
    final categoryIds = <String, int>{};
    final now = Dates.timestamp();
    final entries = <TransactionEntry>[];

    for (final row in rows) {
      final key = '${row.type.value}|${row.categoryName.toLowerCase()}';
      var id = categoryIds[key];
      if (id == null) {
        final existing =
            await _categories.findByName(row.categoryName, row.type);
        id = existing?.id ??
            (await _categories.create(name: row.categoryName, type: row.type))
                .id!;
        categoryIds[key] = id;
      }
      entries.add(TransactionEntry(
        nominal: row.nominal,
        categoryId: id,
        date: Dates.toDb(row.date),
        notes: row.notes,
        createdAt: now,
        updatedAt: now,
      ));
    }

    await _transactions.createMany(entries);
    return entries.length;
  }

  static bool _isHeader(List<Data?> cells) =>
      _text(_cell(cells, 0)).toLowerCase() == 'tanggal';

  static ImportRow? _parseRow(List<Data?> cells) {
    final date = _date(_cell(cells, 0));
    final categoryName = _text(_cell(cells, 2));
    final type = TransactionType.tryParse(_text(_cell(cells, 3)));
    final nominal = _amount(_cell(cells, 4));
    if (date == null ||
        categoryName.isEmpty ||
        type == null ||
        nominal == null ||
        nominal <= 0) {
      return null;
    }
    return ImportRow(
      date: date,
      notes: _text(_cell(cells, 1)),
      categoryName: categoryName,
      type: type,
      nominal: nominal,
    );
  }

  static CellValue? _cell(List<Data?> cells, int index) =>
      index < cells.length ? cells[index]?.value : null;

  static String _text(CellValue? value) => value?.toString().trim() ?? '';

  static int? _amount(CellValue? value) => switch (value) {
        IntCellValue(:final value) => value,
        DoubleCellValue(:final value) => value.round(),
        _ => Money.parse(_text(value)),
      };

  static final _textDateFormats = [
    DateFormat('yyyy-MM-dd'),
    DateFormat('dd/MM/yyyy'),
    DateFormat('d/M/yyyy'),
    DateFormat('dd-MM-yyyy'),
    DateFormat('d-M-yyyy'),
  ];

  static DateTime? _date(CellValue? value) {
    switch (value) {
      case DateCellValue():
        return DateTime(value.year, value.month, value.day);
      case DateTimeCellValue():
        return DateTime(value.year, value.month, value.day);
      case IntCellValue(:final value):
        return _fromExcelSerial(value.toDouble());
      case DoubleCellValue(:final value):
        return _fromExcelSerial(value);
      default:
        final text = _text(value);
        if (text.isEmpty) return null;
        final iso = Dates.fromDb(text);
        if (iso != null) return iso;
        for (final format in _textDateFormats) {
          try {
            return Dates.dateOnly(format.parseStrict(text));
          } on FormatException {
            continue;
          }
        }
        return null;
    }
  }

  /// Excel stores dates as days since 1899-12-30.
  static DateTime? _fromExcelSerial(double serial) {
    if (serial < 1 || serial > 2958465) return null;
    return DateTime(1899, 12, 30 + serial.floor());
  }
}
