import 'dart:async';

import 'package:doku/core/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Preloads one interstitial ad and shows it before export actions.
class InterstitialAdService {
  InterstitialAdService._();

  static final InterstitialAdService instance = InterstitialAdService._();

  InterstitialAd? _ad;
  bool _loading = false;

  void preload() {
    if (_ad != null || _loading) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: AdUnits.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _ad = ad;
        },
        onAdFailedToLoad: (error) {
          _loading = false;
          debugPrint('Interstitial failed to load: $error');
        },
      ),
    );
  }

  /// Shows the ad if one is ready and completes when it is dismissed (or
  /// immediately when no ad is available), so callers can continue.
  Future<void> showIfReady() {
    final ad = _ad;
    if (ad == null) {
      preload();
      return Future.value();
    }
    _ad = null;
    final done = Completer<void>();
    void finish() {
      if (!done.isCompleted) done.complete();
      preload();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        finish();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        finish();
      },
    );
    ad.show();
    return done.future;
  }
}
