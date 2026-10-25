import 'package:doku/core/theme/app_theme.dart';
import 'package:doku/core/utils/formatters.dart';
import 'package:doku/core/widgets/charts.dart';
import 'package:doku/core/widgets/common.dart';
import 'package:doku/core/widgets/transaction_tile.dart';
import 'package:doku/data/models/category.dart';
import 'package:doku/data/models/report_period.dart';
import 'package:doku/data/models/transaction.dart';
import 'package:doku/data/repositories/transaction_repository.dart';
import 'package:doku/data/services/trend_builder.dart';
import 'package:doku/features/import_export/export_action.dart';
import 'package:doku/features/transactions/transaction_form_screen.dart';
import 'package:flutter/material.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportData {
  const _ReportData({
    required this.summary,
    required this.trend,
    required this.income,
    required this.expense,
    required this.entries,
    required this.hasMore,
  });

  final Summary summary;
  final List<TrendPoint> trend;
  final List<CategoryTotal> income;
  final List<CategoryTotal> expense;
  final List<TransactionEntry> entries;
  final bool hasMore;
}

class _ReportsPageState extends State<ReportsPage> with ReloadOnDataChange {
  static const _pageSize = 50;

  final _repo = TransactionRepository();
  ReportPeriod _period = ReportPeriod.currentMonth();
  TransactionType _breakdownType = TransactionType.expense;
  int _visibleEntries = _pageSize;
  _ReportData? _data;
  bool _exporting = false;

  @override
  Future<void> reload() async {
    final generation = beginLoad();
    final period = _period;
    final start = period.startDb;
    final end = period.endDb;
    final limit = _visibleEntries;

    final results = await Future.wait([
      _repo.summary(start: start, end: end),
      _repo.dailyTotals(start: start, end: end),
      _repo.totalsByCategory(TransactionType.income, start: start, end: end),
      _repo.totalsByCategory(TransactionType.expense, start: start, end: end),
      _repo.list(start: start, end: end, limit: limit + 1),
    ]);
    if (!isLatestLoad(generation)) return;

    final entries = results[4] as List<TransactionEntry>;
    setState(() {
      _data = _ReportData(
        summary: results[0] as Summary,
        trend: TrendBuilder.forPeriod(period, results[1] as List<DailyTotal>),
        income: results[2] as List<CategoryTotal>,
        expense: results[3] as List<CategoryTotal>,
        entries: entries.take(limit).toList(),
        hasMore: entries.length > limit,
      );
    });
  }

  void _setPeriod(ReportPeriod period) {
    if (period == _period) return;
    setState(() {
      _period = period;
      _visibleEntries = _pageSize;
    });
    reload();
  }

  void _showMore() {
    setState(() => _visibleEntries += _pageSize);
    reload();
  }

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      await exportTransactions(context, _period);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _data;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: reload,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 8, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Laporan',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    _exporting
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox.square(
                              dimension: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          )
                        : IconButton.filledTonal(
                            tooltip: 'Unduh Excel',
                            onPressed: _export,
                            icon: const Icon(Icons.download_rounded),
                          ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<PeriodType>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    textStyle: theme.textTheme.labelLarge,
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: [
                    for (final type in PeriodType.values)
                      ButtonSegment(value: type, label: Text(type.label)),
                  ],
                  selected: {_period.type},
                  onSelectionChanged: (s) =>
                      _setPeriod(ReportPeriod.of(s.first, DateTime.now())),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _periodNavigator(theme)),
            if (data == null)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SliverList.list(children: _content(data)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _periodNavigator(ThemeData theme) {
    final period = _period;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Sebelumnya',
            onPressed:
                period.canNavigate ? () => _setPeriod(period.previous()) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              period.label,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Berikutnya',
            onPressed: period.canNavigate && !period.hasNoNext
                ? () => _setPeriod(period.next())
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  List<Widget> _content(_ReportData data) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final summary = data.summary;
    final breakdown =
        _breakdownType.isIncome ? data.income : data.expense;
    final groups = TransactionGroup.fromSorted(data.entries);

    return [
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Pemasukan',
                value: Money.format(summary.income),
                color: scheme.income,
                icon: Icons.south_west_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Pengeluaran',
                value: Money.format(summary.expense),
                color: scheme.expense,
                icon: Icons.north_east_rounded,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SurfaceCard(
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Selisih',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            Text(
              '${summary.balance >= 0 ? '+' : '-'}${Money.format(summary.balance.abs())}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: summary.balance >= 0 ? scheme.income : scheme.expense,
              ),
            ),
          ],
        ),
      ),
      const SectionHeader('Grafik'),
      SurfaceCard(
        padding: const EdgeInsets.fromLTRB(8, 20, 16, 16),
        child: data.trend.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Belum ada data.')),
              )
            : TrendBarChart(data.trend),
      ),
      const SectionHeader('Per Kategori'),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SegmentedButton<TransactionType>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
                value: TransactionType.expense, label: Text('Pengeluaran')),
            ButtonSegment(
                value: TransactionType.income, label: Text('Pemasukan')),
          ],
          selected: {_breakdownType},
          onSelectionChanged: (s) => setState(() => _breakdownType = s.first),
        ),
      ),
      SurfaceCard(
        child: breakdown.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Belum ada ${_breakdownType.label.toLowerCase()} pada periode ini.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              )
            : CategoryBreakdown(breakdown),
      ),
      const SectionHeader('Rincian Transaksi'),
      if (groups.isEmpty)
        const EmptyState(
          icon: Icons.event_busy_rounded,
          title: 'Tidak ada transaksi',
          message: 'Belum ada transaksi pada periode ini.',
        )
      else ...[
        for (final group in groups) ...[
          TransactionGroupHeader(group),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final entry in group.items)
                  TransactionTile(
                    entry,
                    onTap: () =>
                        TransactionFormScreen.open(context, entry: entry),
                  ),
              ],
            ),
          ),
        ],
        if (data.hasMore)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: OutlinedButton(
              onPressed: _showMore,
              child: const Text('Tampilkan lebih banyak'),
            ),
          ),
      ],
    ];
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
