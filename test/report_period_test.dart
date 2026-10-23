import 'package:doku/data/models/report_period.dart';
import 'package:doku/data/repositories/transaction_repository.dart';
import 'package:doku/data/services/trend_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportPeriod', () {
    test('weekly starts on Monday and spans 7 days', () {
      // 2024-05-08 is a Wednesday.
      final p = ReportPeriod.of(PeriodType.weekly, DateTime(2024, 5, 8, 15));
      expect(p.startDb, '2024-05-06');
      expect(p.endDb, '2024-05-12');
      expect(p.previous().startDb, '2024-04-29');
      expect(p.next().startDb, '2024-05-13');
    });

    test('monthly covers the real last day of the month', () {
      expect(ReportPeriod.of(PeriodType.monthly, DateTime(2024, 2, 10)).endDb,
          '2024-02-29');
      expect(ReportPeriod.of(PeriodType.monthly, DateTime(2023, 2, 10)).endDb,
          '2023-02-28');
      final dec = ReportPeriod.of(PeriodType.monthly, DateTime(2024, 12, 31));
      expect(dec.next().startDb, '2025-01-01');
      expect(dec.next().endDb, '2025-01-31');
    });

    test('yearly and all', () {
      final y = ReportPeriod.of(PeriodType.yearly, DateTime(2026, 7, 1));
      expect((y.startDb, y.endDb), ('2026-01-01', '2026-12-31'));
      final all = ReportPeriod.of(PeriodType.all, DateTime(2026));
      expect(all.startDb, isNull);
      expect(all.canNavigate, isFalse);
      expect(all.previous(), all);
    });

    test('no next period for the current one', () {
      expect(ReportPeriod.currentMonth().hasNoNext, isTrue);
      expect(ReportPeriod.currentMonth().previous().hasNoNext, isFalse);
    });
  });

  group('TrendBuilder', () {
    test('weekly buckets by weekday', () {
      final p = ReportPeriod.of(PeriodType.weekly, DateTime(2024, 5, 8));
      final points = TrendBuilder.forPeriod(p, [
        DailyTotal(DateTime(2024, 5, 6), 100, 0),
        DailyTotal(DateTime(2024, 5, 12), 0, 50),
      ]);
      expect(points.length, 7);
      expect(points.first.income, 100);
      expect(points.last.expense, 50);
    });

    test('monthly buckets into 7-day blocks incl. day 29-31', () {
      final p = ReportPeriod.of(PeriodType.monthly, DateTime(2024, 1, 1));
      final points = TrendBuilder.forPeriod(p, [
        DailyTotal(DateTime(2024, 1, 31), 0, 70),
      ]);
      expect(points.map((e) => e.label),
          ['1-7', '8-14', '15-21', '22-28', '29-31']);
      expect(points.last.expense, 70);
    });

    test('last months wraps across years', () {
      final points = TrendBuilder.lastMonths(DateTime(2025, 2, 15), 3, [
        DailyTotal(DateTime(2024, 12, 5), 10, 0),
        DailyTotal(DateTime(2025, 2, 1), 0, 20),
        DailyTotal(DateTime(2024, 11, 30), 999, 999),
      ]);
      expect(points.map((e) => e.label), ['Des', 'Jan', 'Feb']);
      expect(points[0].income, 10);
      expect(points[2].expense, 20);
    });
  });
}
