import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../remote/remote_config_service.dart';

bool _adsReady = false;
Future<void> initAds() async {
  try { await MobileAds.instance.initialize(); _adsReady = true; } catch (_) {}
}

/// TEST banner unit. Replace with your real AdMob unit id before publishing.
const _bannerUnit = 'ca-app-pub-3940256099942544/6300978111';

/// Hidden automatically when remote config ads_enabled = false (e.g. for a premium version).
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});
  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? ad;
  @override
  void initState() {
    super.initState();
    if (!_adsReady) return;
    ad = BannerAd(
      adUnitId: _bannerUnit, size: AdSize.banner, request: const AdRequest(),
      listener: BannerAdListener(onAdLoaded: (_) => setState(() {}), onAdFailedToLoad: (a, _) { a.dispose(); ad = null; }),
    )..load();
  }
  @override
  void dispose() { ad?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: remoteConfig,
        builder: (_, __) => (!remoteConfig.adsEnabled || ad == null) ? const SizedBox.shrink() : SizedBox(width: 320, height: 50, child: AdWidget(ad: ad!)),
      );
}
