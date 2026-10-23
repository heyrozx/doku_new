import 'package:doku/core/utils/date_utils.dart';
import 'package:doku/data/models/report_period.dart';
import 'package:doku/data/models/transaction.dart';
import 'package:doku/data/repositories/transaction_repository.dart';

/// Turns per-day totals into chart buckets that suit a report period.
abstract final class TrendBuilder {
  /// - weekly: one bar per day (Sen..Min)
  /// - monthly: one bar per 7-day block (1-7, 8-14, ...)
  /// - yearly: one bar per month
  /// - all: one bar per year present in [days]
  static List<TrendPoint> forPeriod(ReportPeriod period, List<DailyTotal> days) {
    final start = period.start;
    switch (period.type) {
      case PeriodType.weekly:
        const names = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
        return _bucket(
          days,
          List.generate(7, (i) => names[i]),
          (d) => (d.difference(start!).inHours / 24).round(),
        );
      case PeriodType.monthly:
        final lastDay = period.end!.day;
        final blocks = (lastDay / 7).ceil();
        return _bucket(
          days,
          List.generate(blocks, (i) {
            final from = i * 7 + 1;
            final to = (from + 6).clamp(1, lastDay);
            return from == to ? '$from' : '$from-$to';
          }),
          (d) => (d.day - 1) ~/ 7,
        );
      case PeriodType.yearly:
        return _bucket(days, idMonthsShort, (d) => d.month - 1);
      case PeriodType.all:
        if (days.isEmpty) return const [];
        final firstYear = days.first.date.year;
        final lastYear = days.last.date.year;
        return _bucket(
          days,
          [for (var y = firstYear; y <= lastYear; y++) '$y'],
          (d) => d.year - firstYear,
        );
    }
  }

  /// Monthly buckets for the [count] months ending with [lastMonth].
  static List<TrendPoint> lastMonths(
      DateTime lastMonth, int count, List<DailyTotal> days) {
    final first = DateTime(lastMonth.year, lastMonth.month - count + 1);
    return _bucket(
      days,
      [
        for (var i = 0; i < count; i++)
          idMonthsShort[DateTime(first.year, first.month + i).month - 1],
      ],
      (d) => (d.year - first.year) * 12 + d.month - first.month,
    );
  }

  static List<TrendPoint> _bucket(
    List<DailyTotal> days,
    List<String> labels,
    int Function(DateTime date) indexOf,
  ) {
    final income = List<int>.filled(labels.length, 0);
    final expense = List<int>.filled(labels.length, 0);
    for (final day in days) {
      final i = indexOf(day.date);
      if (i < 0 || i >= labels.length) continue;
      income[i] += day.income;
      expense[i] += day.expense;
    }
    return [
      for (var i = 0; i < labels.length; i++)
        TrendPoint(labels[i], income[i], expense[i]),
    ];
  }
}
