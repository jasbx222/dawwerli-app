import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/ads/ad_events.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/catalog.dart';
import '../../../core/api/token_store.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/routes.dart';
import '../../../core/storage/prefs.dart';
import '../../../core/widgets/app_image.dart';
import '../../more/more_data.dart';
import '../domain/sponsored_popup_ad.dart';
import '../presentation/widgets/sponsored_popup.dart';

/// Screens where the popup may appear (browsing only). Everything else —
/// login, posting a request, live offers, checkout, wallet, chat, the page
/// owner side — never shows it.
bool popupAllowedOn(String path) {
  const exact = {
    Routes.home,
    Routes.pages,
    Routes.featuredPages,
    Routes.categories,
    Routes.feed,
    Routes.topProducts,
  };
  if (exact.contains(path)) return true;
  return path.startsWith('/pages/p/') ||
      path.startsWith('/categories/') ||
      path.startsWith('/store/ranking/');
}

/// Pure timing rules, counted in foreground seconds (not wall time), so a
/// customer who leaves the app for an hour does not get an ad on return.
class PopupClock {
  PopupClock({this.sinceLast = 0});

  /// Foreground seconds since the last popup.
  int sinceLast;

  /// Seconds the customer has stayed on allowed screens without a break.
  int onAllowed = 0;

  /// One second of app time. True when a popup is due.
  bool tick({
    required bool foreground,
    required bool allowed,
    required PopupSettings settings,
  }) {
    if (!foreground) return false;
    sinceLast++;
    onAllowed = allowed ? onAllowed + 1 : 0;
    return allowed &&
        sinceLast >= settings.interval.inSeconds &&
        onAllowed >= settings.firstDelay.inSeconds;
  }

  void shown() {
    sinceLast = 0;
    onAllowed = 0;
  }

  /// Back from the background: wait the first delay again.
  void resumed() => onAllowed = 0;
}

/// How often each ad was shown on this device.
class PopupHistory {
  PopupHistory([Map<String, List<int>>? data]) : _d = data ?? {};

  /// id → [total, day (yyyymmdd), shown that day, last shown epoch ms].
  final Map<String, List<int>> _d;

  static int dayOf(DateTime t) => t.year * 10000 + t.month * 100 + t.day;

  factory PopupHistory.decode(String? raw) {
    if (raw == null || raw.isEmpty) return PopupHistory();
    try {
      final m = (jsonDecode(raw) as Map).cast<String, dynamic>();
      return PopupHistory({
        for (final e in m.entries)
          e.key: [for (final v in e.value as List) (v as num).toInt()],
      });
    } on Object {
      return PopupHistory();
    }
  }

  String encode() => jsonEncode(_d);

  int total(String id) => _d[id]?[0] ?? 0;
  int today(String id, DateTime now) {
    final e = _d[id];
    return e != null && e[1] == dayOf(now) ? e[2] : 0;
  }

  int last(String id) => _d[id]?[3] ?? 0;

  void record(String id, DateTime now) {
    final day = dayOf(now);
    final e = _d[id];
    final todayCount = e != null && e[1] == day ? e[2] + 1 : 1;
    _d[id] = [(e?[0] ?? 0) + 1, day, todayCount, now.millisecondsSinceEpoch];
  }

  /// Drops ads that are no longer served.
  void keepOnly(Iterable<String> ids) {
    final keep = ids.toSet();
    _d.removeWhere((k, _) => !keep.contains(k));
  }
}

/// Rotation: ads with an image, under the daily cap (0 = unlimited),
/// least shown on this device first, then least recently shown.
List<SponsoredPopupAd> popupCandidates(
  List<SponsoredPopupAd> ads,
  PopupHistory history,
  int maxPerAdPerDay,
  DateTime now,
) {
  final out = [
    for (final a in ads)
      if (a.id.isNotEmpty &&
          a.image.isNotEmpty &&
          (maxPerAdPerDay <= 0 || history.today(a.id, now) < maxPerAdPerDay))
        a,
  ];
  out.sort((a, b) {
    final byTotal = history.total(a.id).compareTo(history.total(b.id));
    return byTotal != 0
        ? byTotal
        : history.last(a.id).compareTo(history.last(b.id));
  });
  return out;
}

/// Runs for the whole app session once the customer reaches home.
class SponsoredPopupScheduler with WidgetsBindingObserver {
  SponsoredPopupScheduler._(this._c, this._prefs)
    : clock = PopupClock(sinceLast: _prefs.getInt(_kSince) ?? _never),
      history = PopupHistory.decode(_prefs.getString(_kHistory));

  static SponsoredPopupScheduler? _instance;

  /// Idempotent: the first call wins.
  static void start(ProviderContainer container) {
    if (_instance != null) return;
    final s = SponsoredPopupScheduler._(
      container,
      container.read(sharedPrefsProvider),
    );
    _instance = s;
    s._begin();
  }

  static const _kSince = 'ads.popup.sinceLast';
  static const _kHistory = 'ads.popup.history';
  static const _kSettings = 'ads.popup.settings';

  /// Before the first popup ever, only the first delay applies.
  static const _never = 1 << 30;

  /// Pause between failed attempts (offline, no ads, image failed).
  static const _retry = Duration(minutes: 1);
  static const _settingsTtl = Duration(minutes: 10);

  final ProviderContainer _c;
  final SharedPreferences _prefs;
  final PopupClock clock;
  final PopupHistory history;

  PopupSettings? _settings;
  DateTime? _settingsAt;
  DateTime? _retryAt;
  Timer? _timer;
  var _foreground = true;
  var _busy = false;
  var _ticks = 0;

  void _begin() {
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    final cached = _prefs.getString(_kSettings);
    if (cached != null) {
      try {
        _settings = PopupSettings.fromJson(
          (jsonDecode(cached) as Map).cast<String, dynamic>(),
        );
      } on Object {
        _settings = null;
      }
    }
    unawaited(_refreshSettings());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final fg = state == AppLifecycleState.resumed;
    if (fg && !_foreground) clock.resumed();
    _foreground = fg;
    if (!fg) _saveClock();
  }

  Future<void> _refreshSettings() async {
    _settingsAt = DateTime.now();
    try {
      final j = await _c
          .read(apiClientProvider)
          .get<Map<String, dynamic>>('/api/v1/ads/popup-settings');
      final s = PopupSettings.fromJson(j);
      if (s != null) {
        _settings = s;
        await _prefs.setString(_kSettings, jsonEncode(s.toJson()));
      }
    } on Object {
      // Keep the last settings the server sent; none → no popup.
    }
  }

  void _saveClock() =>
      unawaited(_prefs.setInt(_kSince, clock.sinceLast.clamp(0, _never)));

  NavigatorState? get _nav =>
      appRouter.routerDelegate.navigatorKey.currentState;

  String get _path {
    try {
      return appRouter.routerDelegate.currentConfiguration.uri.path;
    } on Object {
      return '';
    }
  }

  /// No dialog, sheet or keyboard over the screen, and a browsing route.
  bool get _screenFree {
    final nav = _nav;
    if (nav == null || !popupAllowedOn(_path)) return false;
    Route<dynamic>? top;
    nav.popUntil((r) {
      top = r;
      return true;
    });
    if (top is! PageRoute) return false;
    final ctx = nav.context;
    return MediaQuery.maybeViewInsetsOf(ctx)?.bottom == 0;
  }

  bool get _customer => _c.read(tokenStoreProvider).role != 'seller';

  void _tick() {
    final settings = _settings;
    final at = _settingsAt;
    if (at == null || DateTime.now().difference(at) > _settingsTtl) {
      unawaited(_refreshSettings());
    }
    if (++_ticks % 15 == 0) _saveClock();
    if (settings == null || _busy) {
      if (_foreground) clock.sinceLast++;
      return;
    }
    final due = clock.tick(
      foreground: _foreground,
      allowed: _foreground && _customer && _screenFree,
      settings: settings,
    );
    if (!due) return;
    final retry = _retryAt;
    if (retry != null && DateTime.now().isBefore(retry)) return;
    _busy = true;
    unawaited(_tryShow(settings).whenComplete(() => _busy = false));
  }

  Future<List<SponsoredPopupAd>> _loadAds() async {
    final api = _c.read(apiClientProvider);
    int? gov;
    try {
      final cat = await _c.read(catalogProvider.future);
      gov = cat.governorateId(_c.read(regionProvider).governorate);
    } on Object {
      gov = null;
    }
    final list = asList(
      await api.get<List<dynamic>>(
        '/api/v1/ads',
        query: {'slot': 'sponsoredOffer', 'governorateId': ?gov},
      ),
    );
    return [for (final a in list) SponsoredPopupAd.fromJson(a)];
  }

  Future<bool> _precache(String image, BuildContext ctx) async {
    var ok = true;
    try {
      await precacheImage(appImage(image), ctx, onError: (_, _) => ok = false);
    } on Object {
      ok = false;
    }
    return ok;
  }

  Future<void> _tryShow(PopupSettings settings) async {
    List<SponsoredPopupAd> ads;
    try {
      ads = await _loadAds();
    } on Object {
      _retryAt = DateTime.now().add(_retry);
      return;
    }
    final now = DateTime.now();
    history.keepOnly(ads.map((a) => a.id));
    for (final ad in popupCandidates(
      ads,
      history,
      settings.maxPerAdPerDay,
      now,
    )) {
      final nav = _nav;
      if (nav == null || !nav.mounted) break;
      // Image failed to load → skip this ad and try the next one.
      if (!await _precache(ad.image, nav.context)) continue;
      if (!_screenFree || !_foreground) break; // customer moved on; try later
      clock.shown();
      history.record(ad.id, now);
      _saveClock();
      unawaited(_prefs.setString(_kHistory, history.encode()));
      final events = _c.read(adEventsProvider);
      if (!nav.mounted) return;
      final action = await showSponsoredPopup(
        nav.context,
        ad: ad,
        duration: settings.duration,
        onSeen: () => unawaited(events.impression(ad.id)),
      );
      if (action != null) {
        unawaited(events.click(ad.id));
        _open(ad, action);
      }
      _retryAt = null;
      return;
    }
    _retryAt = DateTime.now().add(_retry);
  }

  void _open(SponsoredPopupAd ad, PopupAction action) {
    final link = ad.deepLink ?? '';
    if (action == PopupAction.offer && link.startsWith('/')) {
      appRouter.push(link);
    } else if (ad.pageId.isNotEmpty) {
      appRouter.push(Routes.pageProfile(ad.pageId));
    }
  }

  @visibleForTesting
  static void reset() {
    final s = _instance;
    if (s == null) return;
    s._timer?.cancel();
    WidgetsBinding.instance.removeObserver(s);
    _instance = null;
  }
}

/// Drop into the customer home: starts the popup scheduler once.
class SponsoredPopupStarter extends StatefulWidget {
  const SponsoredPopupStarter({super.key});

  @override
  State<SponsoredPopupStarter> createState() => _SponsoredPopupStarterState();
}

class _SponsoredPopupStarterState extends State<SponsoredPopupStarter> {
  @override
  void initState() {
    super.initState();
    SponsoredPopupScheduler.start(
      ProviderScope.containerOf(context, listen: false),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
