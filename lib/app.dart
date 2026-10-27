import 'package:doku/core/constants.dart';
import 'package:doku/core/theme/app_theme.dart';
import 'package:doku/data/services/app_preferences.dart';
import 'package:doku/features/home/home_shell.dart';
import 'package:doku/features/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class DokuApp extends StatelessWidget {
  const DokuApp({
    super.key,
    required this.showOnboarding,
    required this.preferences,
  });

  final bool showOnboarding;
  final AppPreferences preferences;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: preferences.themeMode,
      builder: (context, themeMode, _) => MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        locale: const Locale('id', 'ID'),
        supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: showOnboarding
            ? OnboardingScreen(preferences: preferences)
            : const HomeShell(),
      ),
    );
  }
}
