import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final NumberFormat _rupiah =
    NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
final NumberFormat _compactRupiah =
    NumberFormat.compactCurrency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
final NumberFormat _thousands = NumberFormat.decimalPattern('id');

/// Formatting helpers for Indonesian Rupiah amounts.
abstract final class Money {
  /// `1500000` -> `Rp 1.500.000`
  static String format(num value) => _rupiah.format(value);

  /// `1500000` -> `Rp1,5 jt` (for chart axes and tight spaces).
  static String compact(num value) => _compactRupiah.format(value);

  /// `1500000` -> `1.500.000`
  static String thousands(num value) => _thousands.format(value);

  /// Parses a user/Excel provided amount such as `1.500.000`, `Rp 1.500.000`,
  /// `1500000`, `1500000.0` or `1.500.000,00` into an integer number of rupiah.
  /// Returns `null` when no digits are present.
  static int? parse(String? input) {
    if (input == null) return null;
    var text = input.trim();
    if (text.isEmpty) return null;

    final negative = text.startsWith('-');

    // Indonesian notation: "." groups thousands, "," starts the decimals.
    // Checked first so "1.500" means fifteen hundred, not one and a half.
    final indonesian = RegExp(r'^-?(Rp\.?\s?)?\d{1,3}(\.\d{3})+(,\d*)?$');
    if (!indonesian.hasMatch(text)) {
      // Plain machine numbers (e.g. "1500000" or "1500000.0").
      final plain = num.tryParse(text);
      if (plain != null) return plain.round();
    }

    final commaIndex = text.indexOf(',');
    if (commaIndex >= 0) text = text.substring(0, commaIndex);
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    final value = int.tryParse(digits);
    if (value == null) return null;
    return negative ? -value : value;
  }
}

/// Formats numeric input with Indonesian thousand separators while typing,
/// e.g. `1500000` is displayed as `1.500.000`.
class ThousandsInputFormatter extends TextInputFormatter {
  ThousandsInputFormatter({this.maxDigits = 15});

  /// Upper bound that keeps values well inside SQLite's 64-bit integer range.
  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
          text: '', selection: TextSelection.collapsed(offset: 0));
    }
    if (digits.length > maxDigits) return oldValue;

    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final formatted = _thousands.format(int.parse(digits));

    // Keep the cursor at the same number of digits from the end of the text.
    final digitsAfterCursor = newValue.text
        .substring(newValue.selection.end.clamp(0, newValue.text.length))
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;
    var offset = formatted.length;
    var seen = 0;
    while (offset > 0 && seen < digitsAfterCursor) {
      offset--;
      if (RegExp(r'[0-9]').hasMatch(formatted[offset])) seen++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
