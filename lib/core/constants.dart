import 'package:flutter/foundation.dart';

/// App-wide constants: identifiers, links and ad units.
abstract final class AppConstants {
  static const appName = 'DOKU';
  static const appFullName = 'Dompet Saku';
  static const packageName = 'com.caraguna.dompet_apps';

  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=$packageName';
  static const feedbackFormUrl =
      'https://nexadream.id/product-feedback?product=dompet-saku';
  static const supportEmail = 'halo@nexadream.id';

  static const companyName = 'PT Nexadream Inovasi Digital';
  static const companyLocation = 'Jember, Indonesia';
  static const companyWebsite = 'https://nexadream.id';
}

/// AdMob unit IDs. Google's public test units are used in debug builds so
/// development never generates invalid traffic on the production account.
abstract final class AdUnits {
  static const _bannerProd = 'ca-app-pub-2465007971338713/2900622168';
  static const _interstitialProd = 'ca-app-pub-2465007971338713/4287633671';

  static const _bannerTest = 'ca-app-pub-3940256099942544/6300978111';
  static const _interstitialTest = 'ca-app-pub-3940256099942544/1033173712';

  static String get banner => kReleaseMode ? _bannerProd : _bannerTest;
  static String get interstitial =>
      kReleaseMode ? _interstitialProd : _interstitialTest;
}
