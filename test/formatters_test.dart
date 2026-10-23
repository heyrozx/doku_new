import 'package:doku/core/utils/formatters.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id'));

  group('Money.parse', () {
    test('reads Indonesian thousand separators', () {
      expect(Money.parse('1.500'), 1500);
      expect(Money.parse('1.500.000'), 1500000);
      expect(Money.parse('Rp 1.500.000'), 1500000);
      expect(Money.parse('1.500.000,75'), 1500000);
    });

    test('reads plain machine numbers', () {
      expect(Money.parse('1500000'), 1500000);
      expect(Money.parse('1500000.0'), 1500000);
      expect(Money.parse('  250 '), 250);
    });

    test('returns null without digits', () {
      expect(Money.parse(null), isNull);
      expect(Money.parse(''), isNull);
      expect(Money.parse('abc'), isNull);
    });
  });

  test('Money.format uses rupiah notation', () {
    expect(Money.format(1500000), 'Rp 1.500.000');
  });

  group('ThousandsInputFormatter', () {
    final formatter = ThousandsInputFormatter();

    TextEditingValue type(String text) => formatter.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(
              text: text, selection: TextSelection.collapsed(offset: text.length)),
        );

    test('groups digits while typing', () {
      expect(type('1500000').text, '1.500.000');
      expect(type('1500000').selection.baseOffset, '1.500.000'.length);
    });

    test('strips leading zeros and non-digits', () {
      expect(type('0012a3').text, '123');
      expect(type('').text, '');
    });

    test('rejects input beyond max digits', () {
      final old = TextEditingValue(text: '1');
      final result = ThousandsInputFormatter(maxDigits: 3).formatEditUpdate(
          old, const TextEditingValue(text: '1234'));
      expect(result, old);
    });
  });
}
