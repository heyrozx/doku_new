import 'dart:async';

import 'package:doku/app.dart';
import 'package:doku/data/repositories/category_repository.dart';
import 'package:doku/data/services/ad_service.dart';
import 'package:doku/data/services/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Intl.defaultLocale = 'id';
  await initializeDateFormatting('id');

  final prefs = await AppPreferences.load();
  try {
    await prefs.seedDefaultCategories(CategoryRepository());
  } catch (error, stack) {
    // The app is still usable without starter categories.
    FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack));
  }

  unawaited(MobileAds.instance.initialize().then((_) {
    InterstitialAdService.instance.preload();
  }).catchError((Object error) {
    debugPrint('MobileAds init failed: $error');
  }));

  runApp(DokuApp(showOnboarding: !prefs.hasSeenOnboarding, preferences: prefs));
}
