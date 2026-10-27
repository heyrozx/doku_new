import 'package:doku/data/models/category.dart';
import 'package:doku/data/repositories/category_repository.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent flags. Keys are kept from earlier releases so existing users
/// do not see onboarding again or get duplicate default categories.
class AppPreferences {
  AppPreferences(this._prefs)
    : themeMode = ValueNotifier(_parseThemeMode(_prefs.getString(_themeKey)));

  static const _onboardingKey = 'introduction';
  static const _seededKey = 'is_init_category';
  static const _themeKey = 'theme_mode';

  final SharedPreferences _prefs;

  /// Follows the system until the user picks light or dark in settings.
  final ValueNotifier<ThemeMode> themeMode;

  static AppPreferences? _instance;

  /// The preferences loaded at startup.
  static AppPreferences get instance {
    final prefs = _instance;
    if (prefs == null) throw StateError('AppPreferences.load() not called');
    return prefs;
  }

  static Future<AppPreferences> load() async =>
      _instance = AppPreferences(await SharedPreferences.getInstance());

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _prefs.setString(_themeKey, mode.name);
  }

  static ThemeMode _parseThemeMode(String? value) => ThemeMode.values
      .firstWhere((m) => m.name == value, orElse: () => ThemeMode.system);

  bool get hasSeenOnboarding => _prefs.getInt(_onboardingKey) == 1;

  Future<void> completeOnboarding() => _prefs.setInt(_onboardingKey, 1);

  /// Creates the starter categories on first launch.
  Future<void> seedDefaultCategories(CategoryRepository categories) async {
    if (_prefs.getBool(_seededKey) != null) return;
    if (await categories.count() == 0) {
      for (final (name, description, type) in _defaults) {
        await categories.create(
          name: name,
          description: description,
          type: type,
        );
      }
    }
    await _prefs.setBool(_seededKey, true);
  }

  static const _defaults = [
    ('Gaji Bulanan', 'Kerja Utama', TransactionType.income),
    ('THR', 'Tunjangan Hari Raya', TransactionType.income),
    ('SPP', 'Sumbangan Pembinaan Pendidikan', TransactionType.expense),
    ('Makan', 'Kebutuhan Harian', TransactionType.expense),
    ('Pulsa', 'Paket Data, PLN, Dll.', TransactionType.expense),
    ('Investasi', 'Saham, Obligasi dan Pasar Uang.', TransactionType.expense),
  ];
}
