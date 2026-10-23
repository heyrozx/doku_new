import 'package:doku/data/models/category.dart';
import 'package:doku/data/repositories/category_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent flags. Keys are kept from earlier releases so existing users
/// do not see onboarding again or get duplicate default categories.
class AppPreferences {
  AppPreferences(this._prefs);

  static const _onboardingKey = 'introduction';
  static const _seededKey = 'is_init_category';

  final SharedPreferences _prefs;

  static Future<AppPreferences> load() async =>
      AppPreferences(await SharedPreferences.getInstance());

  bool get hasSeenOnboarding => _prefs.getInt(_onboardingKey) == 1;

  Future<void> completeOnboarding() => _prefs.setInt(_onboardingKey, 1);

  /// Creates the starter categories on first launch.
  Future<void> seedDefaultCategories(CategoryRepository categories) async {
    if (_prefs.getBool(_seededKey) != null) return;
    if (await categories.count() == 0) {
      for (final (name, description, type) in _defaults) {
        await categories.create(
            name: name, description: description, type: type);
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
