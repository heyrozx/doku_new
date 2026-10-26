import 'dart:math' as math;

import 'package:doku/core/theme/app_theme.dart';
import 'package:doku/core/utils/formatters.dart';
import 'package:doku/data/models/transaction.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Grouped income/expense bars.
class TrendBarChart extends StatelessWidget {
  const TrendBarChart(this.points, {super.key, this.height = 220});

  final List<TrendPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maxValue = points.fold<int>(
      0,
      (m, p) => math.max(m, math.max(p.income, p.expense)),
    );
    final maxY = maxValue == 0 ? 1.0 : maxValue * 1.2;
    final barWidth = points.length > 8 ? 6.0 : 10.0;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Column(
      children: [
        SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max) return const SizedBox.shrink();
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          maxValue == 0 ? '' : Money.axis(value),
                          style: labelStyle,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= points.length) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(points[i].label, style: labelStyle),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => scheme.inverseSurface,
                  tooltipBorderRadius: BorderRadius.circular(10),
                  maxContentWidth: 160,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                      BarTooltipItem(
                        '${rodIndex == 0 ? 'Masuk' : 'Keluar'}\n${Money.format(rod.toY)}',
                        TextStyle(
                          color: scheme.onInverseSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < points.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 3,
                    barRods: [
                      _rod(
                        points[i].income.toDouble(),
                        scheme.income,
                        barWidth,
                      ),
                      _rod(
                        points[i].expense.toDouble(),
                        scheme.expense,
                        barWidth,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legend(color: scheme.income, label: 'Pemasukan'),
            const SizedBox(width: 20),
            _Legend(color: scheme.expense, label: 'Pengeluaran'),
          ],
        ),
      ],
    );
  }

  BarChartRodData _rod(double value, Color color, double width) =>
      BarChartRodData(
        toY: value,
        color: color,
        width: width,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

/// Donut chart plus ranked list of categories.
class CategoryBreakdown extends StatelessWidget {
  const CategoryBreakdown(this.totals, {super.key, this.maxItems});

  final List<CategoryTotal> totals;

  /// Limits the list (remaining categories are merged into "Lainnya").
  final int? maxItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = _limited();
    final sum = totals.fold<int>(0, (a, b) => a + b.total);

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 58,
                  startDegreeOffset: -90,
                  sections: [
                    for (var i = 0; i < items.length; i++)
                      PieChartSectionData(
                        value: items[i].total.toDouble(),
                        color: AppColors.chartAt(i),
                        radius: 26,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    Money.compact(sum),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.chartAt(i),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        items[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      Money.format(items[i].total),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(
                      width: 52,
                      child: Text(
                        '${(items[i].share * 100).toStringAsFixed(1)}%',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: items[i].share.clamp(0, 1).toDouble(),
                    minHeight: 6,
                    color: AppColors.chartAt(i),
                    backgroundColor: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<CategoryTotal> _limited() {
    final positive = totals.where((t) => t.total > 0).toList();
    final limit = maxItems;
    if (limit == null || positive.length <= limit) return positive;
    final head = positive.take(limit - 1).toList();
    final rest = positive.skip(limit - 1);
    return [
      ...head,
      CategoryTotal(
        categoryId: -1,
        name: 'Lainnya',
        total: rest.fold(0, (a, b) => a + b.total),
        share: rest.fold(0.0, (a, b) => a + b.share),
      ),
    ];
  }
}
