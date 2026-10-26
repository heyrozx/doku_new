import 'dart:typed_data';

import 'package:doku/core/utils/date_utils.dart';
import 'package:doku/core/utils/formatters.dart';
import 'package:doku/core/widgets/common.dart';
import 'package:doku/data/services/excel_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _service = ExcelService();

  String? _fileName;
  ImportPreview? _preview;
  bool _busy = false;

  Future<void> _pick() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
      );
      if (file == null) return;
      final Uint8List bytes = await file.xFile.readAsBytes();
      final preview = _service.parse(bytes);
      if (!mounted) return;
      setState(() {
        _fileName = file.name;
        _preview = preview;
      });
      if (preview.rows.isEmpty) {
        context.showSnack('Tidak ada baris valid di file ini.', error: true);
      }
    } on FormatException catch (e) {
      if (mounted) context.showSnack(e.message, error: true);
    } catch (_) {
      if (mounted) context.showSnack('Gagal membaca file.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final preview = _preview;
    if (_busy || preview == null || preview.rows.isEmpty) return;
    setState(() => _busy = true);
    try {
      final count = await _service.commit(preview.rows);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text('$count transaksi berhasil diimpor.')),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        context.showSnack('Gagal menyimpan data impor.', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final preview = _preview;
    final total = preview?.rows.fold<int>(0, (sum, r) => sum + r.nominal) ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Impor dari Excel')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Format kolom',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                for (final (i, h) in ExcelService.headers.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: scheme.primaryContainer,
                          child: Text(
                            String.fromCharCode(65 + i),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(h, style: theme.textTheme.bodyMedium),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _hint(i),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  'Gunakan file hasil "Unduh Excel" dari menu Laporan sebagai contoh. '
                  'Kategori yang belum ada akan dibuat otomatis.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            onTap: _busy ? null : _pick,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _fileName == null
                        ? Icons.upload_file_rounded
                        : Icons.check_circle_rounded,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fileName ?? 'Pilih file .xlsx',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _fileName == null
                            ? 'Ketuk untuk memilih file'
                            : 'Ketuk untuk mengganti file',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (preview != null) ...[
            const SectionHeader('Pratinjau'),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row(theme, 'Transaksi valid', '${preview.rows.length}'),
                  _row(theme, 'Total nominal', Money.format(total)),
                  if (preview.skipped.isNotEmpty)
                    _row(
                      theme,
                      'Baris dilewati',
                      preview.skipped.length > 10
                          ? '${preview.skipped.take(10).join(', ')}, …'
                          : preview.skipped.join(', '),
                      color: scheme.error,
                    ),
                ],
              ),
            ),
            if (preview.rows.isNotEmpty) ...[
              const SizedBox(height: 12),
              SurfaceCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (final row in preview.rows.take(5))
                      ListTile(
                        dense: true,
                        title: Text(row.categoryName),
                        subtitle: Text(
                          '${Dates.long(row.date)} • ${row.type.label}',
                        ),
                        trailing: Text(Money.format(row.nominal)),
                      ),
                    if (preview.rows.length > 5)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '+${preview.rows.length - 5} transaksi lainnya',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _busy || (preview?.rows.isEmpty ?? true)
                ? null
                : _import,
            child: _busy
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Text(
                    preview == null || preview.rows.isEmpty
                        ? 'Impor'
                        : 'Impor ${preview.rows.length} transaksi',
                  ),
          ),
        ),
      ),
    );
  }

  static String _hint(int column) => switch (column) {
    0 => '(2024-12-31 atau 31/12/2024)',
    1 => '(opsional)',
    2 => '(nama kategori)',
    3 => '(income/expense atau Pemasukan/Pengeluaran)',
    _ => '(angka, contoh 150000)',
  };

  Widget _row(ThemeData theme, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
