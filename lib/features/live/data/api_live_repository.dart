import 'dart:async';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';
import '../domain/live_request.dart';

/// GET /requests/{id} polled every [ApiDefaults.livePoll]; cancel / raise-price / republish.
class ApiLiveRequestRepository implements LiveRequestRepository {
  const ApiLiveRequestRepository(this.api);
  final ApiClient api;

  static const _cancelled = 'cancelled';
  static const _expired = {'expired', 'closed'};

  Future<LiveRequest> _load(String id) async {
    final r = await api.get<Map<String, dynamic>>('/api/v1/requests/$id');
    final ad = r.om('sponsored');
    final status = r.s('status');
    return LiveRequest(
      id: r.s('id'),
      title: r.s('title'),
      image: r.os('image') ?? '',
      maxPrice: r.i('maxPrice'),
      reachedPages: r.i('reachedPages'),
      seenBy: r.i('seenBy'),
      offerPrices: [for (final p in r.list<num>('offerPrices')) p.toInt()],
      maxOffers: r.i('maxOffers'),
      widensAt: r.t('expandsAt'),
      cancelled: status == _cancelled,
      expired: _expired.contains(status),
      widenedTo: r.list<String>('widenedTo'),
      waitedMinutes: r.i('waitedMinutes'),
      suggestedPrice: r.oi('suggestedPrice'),
      storeOrderId: r.os('storeOrderId'),
      sponsored: ad == null
          ? null
          : SponsoredPage(
              pageId: ad.os('pageId') ?? '',
              name: ad.s('pageName'),
              tagline: ad.s('headline'),
              image: ad.os('image') ?? '',
              adId: ad.os('id') ?? '',
            ),
    );
  }

  @override
  Stream<LiveRequest> watch(String id) async* {
    while (true) {
      final r = await _load(id);
      yield r;
      if (r.cancelled || r.expired) return;
      await Future<void>.delayed(ApiDefaults.livePoll);
    }
  }

  @override
  Future<void> cancel(String id) => api.post<void>('/api/v1/requests/$id/cancel');

  @override
  Future<void> raisePrice(String id, int newMax) =>
      api.post<void>('/api/v1/requests/$id/raise-price', {'maxPrice': newMax});

  @override
  Future<String> republish(String id) async =>
      (await api.post<Map<String, dynamic>>('/api/v1/requests/$id/republish')).s('id');
}
