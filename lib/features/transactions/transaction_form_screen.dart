import 'package:doku/core/theme/app_theme.dart';
import 'package:doku/core/utils/date_utils.dart';
import 'package:doku/core/utils/formatters.dart';
import 'package:doku/core/widgets/common.dart';
import 'package:doku/data/models/category.dart';
import 'package:doku/data/models/transaction.dart';
import 'package:doku/data/repositories/category_repository.dart';
import 'package:doku/data/repositories/transaction_repository.dart';
import 'package:doku/features/categories/category_editor.dart';
import 'package:flutter/material.dart';

/// Create or edit a transaction.
class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({
    super.key,
    this.entry,
    this.initialType = TransactionType.expense,
  });

  /// The transaction to edit, or `null` to create a new one.
  final TransactionEntry? entry;
  final TransactionType initialType;

  static Future<void> open(
    BuildContext context, {
    TransactionEntry? entry,
    TransactionType initialType = TransactionType.expense,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: entry == null,
        builder: (_) =>
            TransactionFormScreen(entry: entry, initialType: initialType),
      ),
    );
  }

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryRepo = CategoryRepository();
  final _transactionRepo = TransactionRepository();

  late final TextEditingController _amount = TextEditingController(
    text: widget.entry != null ? Money.thousands(widget.entry!.nominal) : '',
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.entry?.notes,
  );

  late TransactionType _type = widget.entry?.type ?? widget.initialType;
  late DateTime _date = widget.entry?.dateTime ?? Dates.today();
  int? _categoryId;
  List<Category> _categories = [];
  bool _loadingCategories = true;
  bool _saving = false;

  bool get _isEdit => widget.entry != null;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.entry?.categoryId;
    _loadCategories();
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadCategories({int? select}) async {
    final type = _type;
    final items = await _categoryRepo.all(type: type);
    if (!mounted || type != _type) return;
    setState(() {
      _categories = items;
      _loadingCategories = false;
      final wanted = select ?? _categoryId;
      _categoryId = items.any((c) => c.id == wanted)
          ? wanted
          : (items.isNotEmpty ? items.first.id : null);
    });
  }

  void _changeType(TransactionType type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      _categoryId = null;
      _loadingCategories = true;
    });
    _loadCategories();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _addCategory() async {
    final created = await showCategoryEditor(context, initialType: _type);
    if (created == null || !mounted) return;
    if (created.type != _type) {
      setState(() => _type = created.type);
    }
    await _loadCategories(select: created.id);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final categoryId = _categoryId;
    if (categoryId == null) {
      context.showSnack('Pilih kategori terlebih dahulu.', error: true);
      return;
    }
    final nominal = Money.parse(_amount.text)!;

    setState(() => _saving = true);
    try {
      final id = widget.entry?.id;
      if (id == null) {
        await _transactionRepo.create(
          nominal: nominal,
          categoryId: categoryId,
          date: _date,
          notes: _notes.text,
        );
      } else {
        await _transactionRepo.update(
          id,
          nominal: nominal,
          categoryId: categoryId,
          date: _date,
          notes: _notes.text,
        );
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Transaksi diperbarui.'
                : '${_type.label} ${Money.format(nominal)} tersimpan.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        context.showSnack('Gagal menyimpan transaksi.', error: true);
      }
    }
  }

  Future<void> _delete() async {
    final id = widget.entry?.id;
    if (id == null) return;
    final ok = await context.confirm(
      title: 'Hapus transaksi?',
      message: 'Transaksi ini akan dihapus permanen.',
    );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await _transactionRepo.delete(id);
    if (!mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(content: Text('Transaksi dihapus.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _type.isIncome ? scheme.income : scheme.expense;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Ubah Transaksi' : 'Catat Transaksi'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Hapus',
              onPressed: _delete,
              icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Pengeluaran'),
                  icon: Icon(Icons.north_east_rounded),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Pemasukan'),
                  icon: Icon(Icons.south_west_rounded),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => _changeType(s.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: accent.withValues(alpha: 0.15),
                selectedForegroundColor: accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Jumlah',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amount,
              autofocus: !_isEdit,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsInputFormatter()],
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: accent,
              ),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
                hintText: '0',
              ),
              validator: (v) {
                final value = Money.parse(v);
                if (value == null || value <= 0) {
                  return 'Masukkan jumlah lebih dari 0.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Kategori',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Baru'),
                ),
              ],
            ),
            if (_loadingCategories)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_categories.isEmpty)
              OutlinedButton.icon(
                onPressed: _addCategory,
                icon: const Icon(Icons.add_rounded),
                label: Text('Buat kategori ${_type.label.toLowerCase()}'),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in _categories)
                    ChoiceChip(
                      label: Text(c.name),
                      selected: c.id == _categoryId,
                      onSelected: (_) => setState(() => _categoryId = c.id),
                      selectedColor: accent.withValues(alpha: 0.18),
                      labelStyle: TextStyle(
                        fontWeight: c.id == _categoryId
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: c.id == _categoryId ? accent : null,
                      ),
                      showCheckmark: false,
                    ),
                ],
              ),
            const SizedBox(height: 24),
            Text(
              'Tanggal',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                onTap: _pickDate,
                leading: Icon(Icons.calendar_today_rounded, color: accent),
                title: Text(Dates.full(_date)),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Catatan',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              minLines: 2,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Contoh: makan siang bersama tim (opsional)',
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            12 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
            ),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Text(_isEdit ? 'Simpan Perubahan' : 'Simpan'),
          ),
        ),
      ),
    );
  }
}
