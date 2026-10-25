import 'package:doku/core/theme/app_theme.dart';
import 'package:doku/core/utils/date_utils.dart';
import 'package:doku/core/utils/formatters.dart';
import 'package:doku/core/widgets/banner_ad_view.dart';
import 'package:doku/core/widgets/charts.dart';
import 'package:doku/core/widgets/common.dart';
import 'package:doku/core/widgets/transaction_tile.dart';
import 'package:doku/data/models/category.dart';
import 'package:doku/data/models/report_period.dart';
import 'package:doku/data/models/transaction.dart';
import 'package:doku/data/repositories/transaction_repository.dart';
import 'package:doku/data/services/trend_builder.dart';
import 'package:doku/features/transactions/transaction_form_screen.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.onSeeAllTransactions,
    required this.onOpenReports,
  });

  final VoidCallback onSeeAllTransactions;
  final VoidCallback onOpenReports;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardData {
  const _DashboardData({
    required this.balance,
    required this.month,
    required this.recent,
    required this.trend,
    required this.expenseByCategory,
  });

  final Summary balance;
  final Summary month;
  final List<TransactionEntry> recent;
  final List<TrendPoint> trend;
  final List<CategoryTotal> expenseByCategory;
}

class _DashboardPageState extends State<DashboardPage>
    with ReloadOnDataChange {
  final _repo = TransactionRepository();
  _DashboardData? _data;
  Object? _error;

  @override
  Future<void> reload() async {
    final generation = beginLoad();
    try {
      final now = DateTime.now();
      final month = ReportPeriod.currentMonth();
      final trendStart = DateTime(now.year, now.month - 5);

      final results = await Future.wait([
        _repo.summary(),
        _repo.summary(start: month.startDb, end: month.endDb),
        _repo.list(limit: 5),
        _repo.dailyTotals(
            start: Dates.toDb(trendStart), end: month.endDb),
        _repo.totalsByCategory(TransactionType.expense,
            start: month.startDb, end: month.endDb),
      ]);
      if (!isLatestLoad(generation)) return;
      setState(() {
        _error = null;
        _data = _DashboardData(
          balance: results[0] as Summary,
          month: results[1] as Summary,
          recent: results[2] as List<TransactionEntry>,
          trend: TrendBuilder.lastMonths(
              now, 6, results[3] as List<DailyTotal>),
          expenseByCategory: results[4] as List<CategoryTotal>,
        );
      });
    } catch (e) {
      if (isLatestLoad(generation)) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: reload,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _Header()),
            if (data == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _error != null
                    ? EmptyState(
                        icon: Icons.error_outline_rounded,
                        title: 'Gagal memuat data',
                        action: FilledButton.tonal(
                          onPressed: reload,
                          child: const Text('Coba lagi'),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),
              )
            else
              SliverList.list(children: _content(data)),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(_DashboardData data) {
    final theme = Theme.of(context);
    return [
      _BalanceCard(balance: data.balance.balance, month: data.month),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: _QuickAction(
                type: TransactionType.income,
                onTap: () => TransactionFormScreen.open(context,
                    initialType: TransactionType.income),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                type: TransactionType.expense,
                onTap: () => TransactionFormScreen.open(context,
                    initialType: TransactionType.expense),
              ),
            ),
          ],
        ),
      ),
      const BannerAdView(),
      SectionHeader(
        'Tren 6 Bulan',
        actionLabel: 'Laporan',
        onAction: widget.onOpenReports,
      ),
      SurfaceCard(
        padding: const EdgeInsets.fromLTRB(8, 20, 16, 16),
        child: TrendBarChart(data.trend, height: 200),
      ),
      SectionHeader('Pengeluaran ${idMonths[DateTime.now().month - 1]}'),
      SurfaceCard(
        child: data.expenseByCategory.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Belum ada pengeluaran bulan ini.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              )
            : CategoryBreakdown(data.expenseByCategory, maxItems: 5),
      ),
      SectionHeader(
        'Transaksi Terakhir',
        actionLabel: 'Lihat semua',
        onAction: widget.onSeeAllTransactions,
      ),
      if (data.recent.isEmpty)
        EmptyState(
          icon: Icons.receipt_long_rounded,
          title: 'Belum ada transaksi',
          message: 'Mulai catat pemasukan dan pengeluaranmu hari ini.',
          action: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => TransactionFormScreen.open(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Catat transaksi'),
          ),
        )
      else
        SurfaceCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (final entry in data.recent)
                TransactionTile(
                  entry,
                  showDate: true,
                  onTap: () => TransactionFormScreen.open(context, entry: entry),
                ),
            ],
          ),
        ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header();

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 19) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset('assets/images/logo.png', width: 44, height: 44),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                Text(
                  'Dompet Saku',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.month});

  final int balance;
  final Summary month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const onCard = Colors.white;
    final ratio = month.spendingRatio;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -60,
            top: -70,
            child: _Bubble(size: 180, color: onCard.withValues(alpha: 0.08)),
          ),
          Positioned(
            right: 40,
            top: 50,
            child: _Bubble(size: 70, color: onCard.withValues(alpha: 0.06)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Saldo',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: onCard.withValues(alpha: 0.85))),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${balance < 0 ? '-' : ''}${Money.format(balance.abs())}',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: onCard,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _MonthStat(
                      icon: Icons.south_west_rounded,
                      label: 'Pemasukan',
                      value: month.income,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: onCard.withValues(alpha: 0.25),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MonthStat(
                      icon: Icons.north_east_rounded,
                      label: 'Pengeluaran',
                      value: month.expense,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0, 1).toDouble(),
                  minHeight: 6,
                  color: ratio > 1 ? const Color(0xFFFDE68A) : onCard,
                  backgroundColor: onCard.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                month.income == 0
                    ? 'Belum ada pemasukan bulan ini'
                    : 'Terpakai ${(ratio * 100).toStringAsFixed(0)}% dari pemasukan bulan ini',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: onCard.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthStat extends StatelessWidget {
  const _MonthStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const onCard = Colors.white;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: onCard.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: onCard, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: onCard.withValues(alpha: 0.8))),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  Money.format(value),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: onCard,
                    fontWeight: FontWeight.w700,
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

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.type, required this.onTap});

  final TransactionType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          TypeIcon(type, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tambah',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    type.label,
                    maxLines: 1,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
