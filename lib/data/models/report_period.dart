import 'package:doku/core/utils/date_utils.dart';

enum PeriodType {
  weekly('Mingguan'),
  monthly('Bulanan'),
  yearly('Tahunan'),
  all('Semua');

  const PeriodType(this.label);
  final String label;
}

/// An inclusive date range used for reports and queries.
///
/// [start] and [end] are `null` only for [PeriodType.all].
class ReportPeriod {
  const ReportPeriod._(this.type, this.start, this.end);

  factory ReportPeriod.of(PeriodType type, DateTime anchor) {
    final day = Dates.dateOnly(anchor);
    switch (type) {
      case PeriodType.weekly:
        final start = Dates.startOfWeek(day);
        return ReportPeriod._(type, start, Dates.addDays(start, 6));
      case PeriodType.monthly:
        return ReportPeriod._(
          type,
          DateTime(day.year, day.month),
          Dates.endOfMonth(day),
        );
      case PeriodType.yearly:
        return ReportPeriod._(
          type,
          DateTime(day.year),
          DateTime(day.year, 12, 31),
        );
      case PeriodType.all:
        return const ReportPeriod._(PeriodType.all, null, null);
    }
  }

  factory ReportPeriod.currentMonth() =>
      ReportPeriod.of(PeriodType.monthly, DateTime.now());

  final PeriodType type;
  final DateTime? start;
  final DateTime? end;

  String? get startDb => start == null ? null : Dates.toDb(start!);
  String? get endDb => end == null ? null : Dates.toDb(end!);

  bool get canNavigate => type != PeriodType.all;

  /// Whether the following period would lie entirely in the future.
  bool get hasNoNext => end == null || !end!.isBefore(Dates.today());

  ReportPeriod previous() => _shift(-1);
  ReportPeriod next() => _shift(1);

  ReportPeriod _shift(int step) {
    final s = start;
    if (s == null) return this;
    switch (type) {
      case PeriodType.weekly:
        return ReportPeriod.of(type, Dates.addDays(s, 7 * step));
      case PeriodType.monthly:
        return ReportPeriod.of(type, DateTime(s.year, s.month + step));
      case PeriodType.yearly:
        return ReportPeriod.of(type, DateTime(s.year + step));
      case PeriodType.all:
        return this;
    }
  }

  String get label {
    final s = start;
    final e = end;
    if (s == null || e == null) return 'Semua Waktu';
    switch (type) {
      case PeriodType.weekly:
        if (s.year != e.year) return '${Dates.long(s)} - ${Dates.long(e)}';
        return '${Dates.dayMonth(s)} - ${Dates.dayMonth(e)} ${e.year}';
      case PeriodType.monthly:
        return Dates.monthYear(s);
      case PeriodType.yearly:
        return '${s.year}';
      case PeriodType.all:
        return 'Semua Waktu';
    }
  }

  /// File-name friendly label, e.g. `Bulanan_Mei_2024`.
  String get fileLabel =>
      '${type.label}_${label.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}';

  @override
  bool operator ==(Object other) =>
      other is ReportPeriod &&
      other.type == type &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(type, start, end);
}
