import 'package:intl/intl.dart';

const List<String> idMonths = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const List<String> idMonthsShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

final DateFormat _dbDate = DateFormat('yyyy-MM-dd');
final DateFormat _timestamp = DateFormat('yyyy-MM-dd HH:mm:ss');

/// Date helpers. Transaction dates are stored as `yyyy-MM-dd` strings so they
/// sort and compare correctly as text in SQLite.
abstract final class Dates {
  static DateTime today() => dateOnly(DateTime.now());

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// `2024-05-06`
  static String toDb(DateTime date) => _dbDate.format(date);

  /// Parses a `yyyy-MM-dd` string (a trailing time part is ignored);
  /// returns `null` when invalid.
  static DateTime? fromDb(String? value) {
    if (value == null || value.length < 10) return null;
    try {
      return _dbDate.parseStrict(value.substring(0, 10));
    } on FormatException {
      return null;
    }
  }

  /// `2024-05-06 13:45:00`
  static String timestamp([DateTime? at]) =>
      _timestamp.format(at ?? DateTime.now());

  /// `6 Mei 2024`
  static String long(DateTime date) =>
      '${date.day} ${idMonths[date.month - 1]} ${date.year}';

  /// `6 Mei`
  static String dayMonth(DateTime date) =>
      '${date.day} ${idMonthsShort[date.month - 1]}';

  /// `Senin, 6 Mei 2024`
  static String full(DateTime date) =>
      '${DateFormat('EEEE', 'id').format(date)}, ${long(date)}';

  /// "Hari ini", "Kemarin" or the full date.
  static String relative(DateTime date) {
    final day = dateOnly(date);
    final now = today();
    if (day == now) return 'Hari ini';
    if (day == addDays(now, -1)) return 'Kemarin';
    return full(date);
  }

  static String monthYear(DateTime date) =>
      '${idMonths[date.month - 1]} ${date.year}';

  /// Monday of the week containing [date].
  static DateTime startOfWeek(DateTime date) =>
      DateTime(date.year, date.month, date.day - (date.weekday - DateTime.monday));

  /// Adds whole calendar days (safe across daylight-saving changes).
  static DateTime addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0);
}
