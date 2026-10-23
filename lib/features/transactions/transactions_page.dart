import 'package:doku/core/utils/date_utils.dart';
import 'package:doku/core/widgets/common.dart';
import 'package:doku/core/widgets/transaction_tile.dart';
import 'package:doku/data/models/category.dart';
import 'package:doku/data/models/transaction.dart';
import 'package:doku/data/repositories/transaction_repository.dart';
import 'package:doku/features/transactions/transaction_form_screen.dart';
import 'package:flutter/material.dart';

/// Paged list of all transactions, grouped per day.
class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage>
    with ReloadOnDataChange {
  static const _pageSize = 30;

  final _repo = TransactionRepository();
  final _scroll = ScrollController();

  TransactionType? _filter;
  final List<TransactionEntry> _items = [];
  bool _initialLoad = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 400) _loadMore();
  }

  /// Reloads from the first page, keeping as many rows as are visible.
  @override
  Future<void> reload() async {
    final generation = beginLoad();
    final count = _items.length < _pageSize ? _pageSize : _items.length;
    final rows = await _repo.list(type: _filter, limit: count);
    if (!isLatestLoad(generation)) return;
    setState(() {
      _items
        ..clear()
        ..addAll(rows);
      _hasMore = rows.length == count;
      _initialLoad = false;
      _loadingMore = false;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _initialLoad) return;
    setState(() => _loadingMore = true);
    final generation = currentLoad;
    final rows = await _repo.list(
        type: _filter, limit: _pageSize, offset: _items.length);
    if (!isLatestLoad(generation)) {
      if (mounted) setState(() => _loadingMore = false);
      return;
    }
    setState(() {
      _items.addAll(rows);
      _hasMore = rows.length == _pageSize;
      _loadingMore = false;
    });
  }

  void _setFilter(TransactionType? type) {
    if (type == _filter) return;
    setState(() {
      _filter = type;
      _items.clear();
      _initialLoad = true;
      _hasMore = true;
    });
    reload();
  }

  Future<void> _deleteDay(TransactionGroup group) async {
    final date = Dates.toDb(group.date);
    final ok = await context.confirm(
      title: 'Hapus semua transaksi?',
      message:
          'Semua transaksi pada ${Dates.long(group.date)} akan dihapus permanen.',
      confirmLabel: 'Hapus semua',
    );
    if (!ok) return;
    final count = await _repo.deleteOnDate(date);
    if (mounted) context.showSnack('$count transaksi dihapus.');
  }

  @override
  Widget build(BuildContext context) {
    final groups = TransactionGroup.fromSorted(_items);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Transaksi',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Semua',
                  selected: _filter == null,
                  onTap: () => _setFilter(null),
                ),
                for (final type in TransactionType.values)
                  _FilterChip(
                    label: type.label,
                    selected: _filter == type,
                    onTap: () => _setFilter(type),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: reload,
              child: _initialLoad
                  ? const Center(child: CircularProgressIndicator())
                  : groups.isEmpty
                      ? ListView(
                          children: const [
                            EmptyState(
                              icon: Icons.receipt_long_rounded,
                              title: 'Belum ada transaksi',
                              message:
                                  'Tekan tombol "Catat" untuk menambahkan transaksi pertamamu.',
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.only(bottom: 96),
                          itemCount: groups.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (i >= groups.length) {
                              return const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                    child: CircularProgressIndicator()),
                              );
                            }
                            final group = groups[i];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TransactionGroupHeader(
                                  group,
                                  onLongPress: () => _deleteDay(group),
                                ),
                                SurfaceCard(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Column(
                                    children: [
                                      for (final entry in group.items)
                                        TransactionTile(
                                          entry,
                                          onTap: () =>
                                              TransactionFormScreen.open(
                                                  context,
                                                  entry: entry),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
