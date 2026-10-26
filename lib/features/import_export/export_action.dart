import 'package:doku/core/widgets/common.dart';
import 'package:doku/data/models/report_period.dart';
import 'package:doku/data/repositories/transaction_repository.dart';
import 'package:doku/data/services/ad_service.dart';
import 'package:doku/data/services/excel_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Exports the transactions of [period] to an `.xlsx` file chosen by the user.
Future<void> exportTransactions(
  BuildContext context,
  ReportPeriod period,
) async {
  try {
    final entries = await TransactionRepository().list(
      start: period.startDb,
      end: period.endDb,
    );
    if (!context.mounted) return;
    if (entries.isEmpty) {
      context.showSnack('Tidak ada transaksi untuk diekspor.');
      return;
    }

    await InterstitialAdService.instance.showIfReady();

    final bytes = ExcelService().buildWorkbook(entries);
    final uri = await FilePicker.saveFile(
      dialogTitle: 'Simpan laporan',
      fileName: 'DOKU_Laporan_${period.fileLabel}.xlsx',
      bytes: bytes,
      mimeType: ExcelService.mimeType,
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
    );
    if (!context.mounted) return;
    if (uri != null) {
      context.showSnack('Laporan berhasil disimpan.');
    }
  } catch (e) {
    if (context.mounted) {
      context.showSnack('Gagal mengekspor laporan.', error: true);
    }
  }
}
