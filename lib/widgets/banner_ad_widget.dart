import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config.dart';
import '../services/ad_service.dart';

/// A persistent AdMob banner. Reserves no space until an ad has loaded, so it
/// never leaves an empty gray strip if loading fails or the platform is
/// unsupported (web/desktop).
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_supported && _ad == null) _loadAd();
  }

  Future<void> _loadAd() async {
    final isIOS = !kIsWeb && Platform.isIOS;
    // Standard-height anchored adaptive banner: full screen width, with a
    // Google-optimized height (~50px) the creative fills snugly. The "large"
    // variant returns a much taller box that leaves empty space above/below a
    // standard creative, so we deliberately avoid it here.
    final width = MediaQuery.sizeOf(context).width.truncate();
    final size =
        // ignore: deprecated_member_use
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    final ad = BannerAd(
      adUnitId: AdConfig.bannerUnitId(isIOS),
      size: size ?? AdSize.banner,
      request: adRequest,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
