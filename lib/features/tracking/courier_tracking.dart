import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/api/token_store.dart';

/// Courier's last shared position for one order, as the customer or the page
/// sees it. [active] is false when the courier link is not sharing.
class CourierLocation {
  const CourierLocation({
    required this.active,
    this.latitude,
    this.longitude,
    this.heading,
    this.updatedAt,
    this.distanceMeters,
    this.etaMinutes,
  });

  static const inactive = CourierLocation(active: false);

  final bool active;
  final double? latitude;
  final double? longitude;
  final double? heading;
  final DateTime? updatedAt;
  final double? distanceMeters;
  final int? etaMinutes;

  bool get hasPoint => active && latitude != null && longitude != null;

  static double? _d(Object? v) => (v as num?)?.toDouble();

  factory CourierLocation.fromJson(Map<String, dynamic> j) {
    final at = j['updatedAt'];
    return CourierLocation(
      active: j['active'] == true,
      latitude: _d(j['latitude']),
      longitude: _d(j['longitude']),
      heading: _d(j['heading']),
      updatedAt: at is String ? DateTime.tryParse(at) : null,
      distanceMeters: _d(j['distanceMeters']),
      etaMinutes: (j['etaMinutes'] as num?)?.round(),
    );
  }
}

/// The page's courier link for an order out for delivery.
class CourierTrackingLink {
  const CourierTrackingLink({
    required this.url,
    this.sharing = false,
    this.lastLocationAt,
  });
  final String url;
  final bool sharing;
  final DateTime? lastLocationAt;

  static CourierTrackingLink? fromOrderJson(Map<String, dynamic> j) {
    final t = j['courierTracking'];
    if (t is Map) {
      final m = t.cast<String, dynamic>();
      final url = m['url'];
      if (url is String && url.isNotEmpty) {
        final at = m['lastLocationAt'];
        return CourierTrackingLink(
          url: url,
          sharing: m['sharing'] == true,
          lastLocationAt: at is String ? DateTime.tryParse(at) : null,
        );
      }
    }
    final url = j['courierTrackingUrl'];
    return url is String && url.isNotEmpty
        ? CourierTrackingLink(url: url)
        : null;
  }

  factory CourierTrackingLink.fromJson(Map<String, dynamic> j) =>
      fromOrderJson({'courierTracking': j}) ??
      const CourierTrackingLink(url: '');
}

/// «يوصل تقريباً خلال X دقيقة» line for a sharing courier.
String courierEtaLabel(CourierLocation l) {
  final eta = l.etaMinutes;
  if (eta == null) return 'المندوب بالطريق';
  if (eta <= 1) return 'المندوب بالطريق · يوصل تقريباً خلال دقيقة';
  if (eta == 2) return 'المندوب بالطريق · يوصل تقريباً خلال دقيقتين';
  return 'المندوب بالطريق · يوصل تقريباً خلال $eta دقيقة';
}

/// «آخر تحديث قبل ...» for the courier's last position.
String courierUpdatedLabel(DateTime? at, {DateTime? now}) {
  if (at == null) return '';
  final s = (now ?? DateTime.now()).difference(at).inSeconds;
  if (s < 15) return 'آخر تحديث هسه';
  if (s < 60) return 'آخر تحديث قبل $s ثانية';
  final m = s ~/ 60;
  if (m < 60) return m == 1 ? 'آخر تحديث قبل دقيقة' : 'آخر تحديث قبل $m دقيقة';
  return 'آخر تحديث قبل أكثر من ساعة';
}

/// Courier-location reads and the page's link actions.
class CourierTrackingRepo {
  const CourierTrackingRepo(this._api);
  final ApiClient _api;

  Future<CourierLocation> forCustomer(String storeOrderId) async =>
      CourierLocation.fromJson(
        await _api.get<Map<String, dynamic>>(
          '/api/v1/store/orders/$storeOrderId/courier-location',
        ),
      );

  Future<CourierLocation> forPage(String storeOrderId) async =>
      CourierLocation.fromJson(
        await _api.get<Map<String, dynamic>>(
          '/api/v1/pages/me/store-orders/$storeOrderId/courier-location',
        ),
      );

  /// New link; the old one stops working straight away.
  Future<CourierTrackingLink> regenerate(String storeOrderId) async =>
      CourierTrackingLink.fromJson(
        await _api.post<Map<String, dynamic>>(
          '/api/v1/pages/me/store-orders/$storeOrderId/tracking-link',
          const {},
        ),
      );
}

final courierTrackingRepoProvider = Provider<CourierTrackingRepo>(
  (ref) => CourierTrackingRepo(ref.watch(apiClientProvider)),
);

/// Pushes from the live hub for one order (`courierMoved`). Polling covers
/// any gap, so failures here are silent.
abstract class CourierPushes {
  Stream<CourierLocation> watch(String storeOrderId);
}

class SignalRCourierPushes implements CourierPushes {
  SignalRCourierPushes(this.baseUrl, this.tokens);
  final String baseUrl;
  final TokenStore tokens;

  @override
  Stream<CourierLocation> watch(String storeOrderId) {
    HubConnection? hub;
    late final StreamController<CourierLocation> out;
    Future<void> join() async {
      try {
        await hub?.invoke('WatchOrder', args: [storeOrderId]);
      } catch (_) {}
    }

    out = StreamController<CourierLocation>(
      onListen: () async {
        try {
          await tokens.load();
          final root = baseUrl.endsWith('/')
              ? baseUrl.substring(0, baseUrl.length - 1)
              : baseUrl;
          final h = HubConnectionBuilder()
              .withUrl(
                '$root/hubs/live',
                options: HttpConnectionOptions(
                  accessTokenFactory: () async => tokens.access ?? '',
                ),
              )
              .withAutomaticReconnect()
              .build();
          hub = h;
          h.on('courierMoved', (args) {
            if (args == null || args.length < 2) return;
            if ('${args[0]}'.toLowerCase() != storeOrderId.toLowerCase()) {
              return;
            }
            final m = args[1];
            if (m is Map && !out.isClosed) {
              out.add(CourierLocation.fromJson(m.cast<String, dynamic>()));
            }
          });
          h.onreconnected(({connectionId}) => join());
          await h.start();
          if (out.isClosed) {
            await h.stop();
            return;
          }
          await join();
        } catch (_) {}
      },
      onCancel: () async {
        final h = hub;
        hub = null;
        try {
          await h?.invoke('UnwatchOrder', args: [storeOrderId]);
        } catch (_) {}
        try {
          await h?.stop();
        } catch (_) {}
      },
    );
    return out.stream;
  }
}

final courierPushesProvider = Provider<CourierPushes>(
  (ref) => SignalRCourierPushes(
    ref.watch(apiBaseUrlProvider),
    ref.watch(tokenStoreProvider),
  ),
);
