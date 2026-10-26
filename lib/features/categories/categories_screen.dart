import 'package:doku/core/widgets/common.dart';
import 'package:doku/data/models/category.dart';
import 'package:doku/data/repositories/category_repository.dart';
import 'package:doku/features/categories/category_editor.dart';
import 'package:flutter/material.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin, ReloadOnDataChange {
  final _repo = CategoryRepository();
  late final TabController _tabs = TabController(length: 2, vsync: this);
  List<Category>? _categories;

  static const _tabTypes = [TransactionType.expense, TransactionType.income];

  @override
  Future<void> reload() async {
    final generation = beginLoad();
    final items = await _repo.all();
    if (isLatestLoad(generation)) setState(() => _categories = items);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final created = await showCategoryEditor(
      context,
      initialType: _tabTypes[_tabs.index],
    );
    if (created == null || !mounted) return;
    _tabs.animateTo(_tabTypes.indexOf(created.type));
    context.showSnack('Kategori "${created.name}" ditambahkan.');
  }

  Future<void> _edit(Category category) async {
    final saved = await showCategoryEditor(context, category: category);
    if (saved == null || !mounted) return;
    _tabs.animateTo(_tabTypes.indexOf(saved.type));
    context.showSnack('Kategori "${saved.name}" diperbarui.');
  }

  Future<void> _delete(Category category) async {
    final id = category.id;
    if (id == null) return;
    final used = await _repo.usageCount(id);
    if (!mounted) return;
    final ok = await context.confirm(
      title: 'Hapus kategori?',
      message: used == 0
          ? 'Kategori "${category.name}" akan dihapus.'
          : 'Kategori "${category.name}" dipakai oleh $used transaksi. '
                'Kategori beserta transaksinya akan dihapus permanen.',
    );
    if (!ok) return;
    await _repo.delete(id);
    if (mounted) context.showSnack('Kategori "${category.name}" dihapus.');
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Pengeluaran'),
            Tab(text: 'Pemasukan'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Kategori'),
      ),
      body: categories == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                for (final type in _tabTypes)
                  _CategoryList(
                    items: categories.where((c) => c.type == type).toList(),
                    type: type,
                    onEdit: _edit,
                    onDelete: _delete,
                  ),
              ],
            ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.items,
    required this.type,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Category> items;
  final TransactionType type;
  final ValueChanged<Category> onEdit;
  final ValueChanged<Category> onDelete;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        children: [
          EmptyState(
            icon: Icons.label_outline_rounded,
            title: 'Belum ada kategori ${type.label.toLowerCase()}',
            message: 'Tambahkan kategori untuk mengelompokkan transaksimu.',
          ),
        ],
      );
    }
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 96),
      children: [
        SurfaceCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (final c in items)
                ListTile(
                  onTap: () => onEdit(c),
                  leading: TypeIcon(type, size: 40),
                  title: Text(
                    c.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: (c.description ?? '').isEmpty
                      ? null
                      : Text(
                          c.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  trailing: IconButton(
                    tooltip: 'Hapus',
                    onPressed: () => onDelete(c),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
