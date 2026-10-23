import 'package:doku/core/widgets/common.dart';
import 'package:doku/data/models/category.dart';
import 'package:doku/data/repositories/category_repository.dart';
import 'package:flutter/material.dart';

/// Opens a bottom sheet to create or edit a category. Resolves to the saved
/// category, or `null` when cancelled.
Future<Category?> showCategoryEditor(
  BuildContext context, {
  Category? category,
  TransactionType initialType = TransactionType.expense,
}) {
  return showModalBottomSheet<Category>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CategoryEditor(
      category: category,
      initialType: category?.type ?? initialType,
    ),
  );
}

class _CategoryEditor extends StatefulWidget {
  const _CategoryEditor({this.category, required this.initialType});

  final Category? category;
  final TransactionType initialType;

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  final _formKey = GlobalKey<FormState>();
  final _repo = CategoryRepository();
  late final _name = TextEditingController(text: widget.category?.name);
  late final _description =
      TextEditingController(text: widget.category?.description);
  late TransactionType _type = widget.initialType;
  bool _saving = false;

  bool get _isEdit => widget.category != null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final name = _name.text.trim();
      final existing = await _repo.findByName(name, _type);
      if (existing != null && existing.id != widget.category?.id) {
        if (mounted) {
          context.showSnack('Kategori "$name" sudah ada.', error: true);
        }
        return;
      }

      final Category saved;
      final current = widget.category;
      if (current == null) {
        saved = await _repo.create(
            name: name, description: _description.text, type: _type);
      } else {
        saved = Category(
          id: current.id,
          name: name,
          description: _description.text,
          type: _type,
          createdAt: current.createdAt,
        );
        await _repo.update(saved);
      }
      if (mounted) Navigator.pop(context, saved);
    } catch (e) {
      if (mounted) context.showSnack('Gagal menyimpan kategori.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? 'Ubah Kategori' : 'Kategori Baru',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
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
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              autofocus: !_isEdit,
              maxLength: 40,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama kategori',
                prefixIcon: Icon(Icons.label_outline_rounded),
                counterText: '',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nama kategori wajib diisi.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (opsional)',
                prefixIcon: Icon(Icons.notes_rounded),
                counterText: '',
              ),
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Kategori'),
            ),
          ],
        ),
      ),
    );
  }
}
