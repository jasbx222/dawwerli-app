import '../../../core/api/api_client.dart';

/// A sponsored ad («عرض مُموّل») as shown in the timed popup.
/// Comes from `GET /api/v1/ads?slot=sponsoredOffer`.
class SponsoredPopupAd {
  const SponsoredPopupAd({
    required this.id,
    required this.pageId,
    required this.pageName,
    required this.title,
    required this.headline,
    required this.image,
    this.discountPercent = 0,
    this.deepLink,
    this.pageImage = '',
    this.pageHandle = '',
    this.pageVerified = false,
  });

  factory SponsoredPopupAd.fromJson(Map<String, dynamic> j) => SponsoredPopupAd(
    id: j.s('id'),
    pageId: j.os('pageId') ?? '',
    pageName: j.s('pageName'),
    title: j.s('title'),
    headline: j.s('headline'),
    image: j.os('image') ?? '',
    discountPercent: j.i('discountPercent'),
    deepLink: j.os('deepLink'),
    pageImage: j.os('pageImage') ?? '',
    pageHandle: j.os('pageHandle') ?? '',
    pageVerified: j.b('pageVerified'),
  );

  final String id;
  final String pageId;
  final String pageName;
  final String title;
  final String headline;
  final String image;
  final int discountPercent;
  final String? deepLink;
  final String pageImage;
  final String pageHandle;
  final bool pageVerified;
}

/// Popup timing set by the admin (`GET /api/v1/ads/popup-settings`).
/// There are no defaults in the app: without settings, no popup is shown.
class PopupSettings {
  const PopupSettings({
    required this.duration,
    required this.interval,
    required this.firstDelay,
    required this.maxPerAdPerDay,
  });

  /// Null when the payload is not usable.
  static PopupSettings? fromJson(Map<String, dynamic> j) {
    final duration = j.oi('durationSec');
    final interval = j.oi('intervalMin');
    final delay = j.oi('firstDelaySec');
    if (duration == null || duration <= 0) return null;
    if (interval == null || interval <= 0) return null;
    if (delay == null || delay < 0) return null;
    return PopupSettings(
      duration: Duration(seconds: duration),
      interval: Duration(minutes: interval),
      firstDelay: Duration(seconds: delay),
      maxPerAdPerDay: j.oi('maxPerAdPerDay') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'durationSec': duration.inSeconds,
    'intervalMin': interval.inMinutes,
    'firstDelaySec': firstDelay.inSeconds,
    'maxPerAdPerDay': maxPerAdPerDay,
  };

  final Duration duration;
  final Duration interval;
  final Duration firstDelay;

  /// Times one ad may show on this device per day. 0 = unlimited.
  final int maxPerAdPerDay;
}
