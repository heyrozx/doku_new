import 'package:doku/data/services/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('theme mode follows the system until the user picks one', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await AppPreferences.load();
    expect(prefs.themeMode.value, ThemeMode.system);
    expect(AppPreferences.instance, same(prefs));

    await prefs.setThemeMode(ThemeMode.dark);
    expect(prefs.themeMode.value, ThemeMode.dark);

    final reloaded = await AppPreferences.load();
    expect(reloaded.themeMode.value, ThemeMode.dark);
  });

  test('unknown stored theme values fall back to system', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'sepia'});
    final prefs = await AppPreferences.load();
    expect(prefs.themeMode.value, ThemeMode.system);
  });
}
