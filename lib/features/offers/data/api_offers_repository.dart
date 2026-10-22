import '../../../core/api/api_client.dart';
import '../../../core/l10n/offer_strings.dart';
import '../domain/offer.dart';

/// GET /requests/{id}/offers, POST /requests/{id}/select, GET /requests/{id}/selection,
/// POST /orders/{orderId}/no-reply.
class ApiOffersRepository implements OffersRepository {
  ApiOffersRepository(this.api);
  final ApiClient api;

  static const _conflict = 'selection.exists';
  final _orders = <String, String>{};

  @override
  Future<OffersBoard> offers(String requestId) async {
    final j = await api.get<Map<String, dynamic>>(
      '/api/v1/requests/$requestId/offers',
    );
    return OffersBoard(
      requestId: j.s('requestId'),
      maxOffers: j.i('maxOffers'),
      offers: [for (final o in j.l('offers')) offerFromJson(o)],
    );
  }

  @override
  Future<Selection> select(
    String requestId,
    String offerId, [
    SelectDelivery? delivery,
  ]) async {
    try {
      return _selection(
        await api.post<Map<String, dynamic>>(
          '/api/v1/requests/$requestId/select',
          {'offerId': offerId, ...?delivery?.toJson()},
        ),
      );
    } on ApiException catch (e) {
      if (e.code == _conflict) throw const SelectionConflict();
      rethrow;
    }
  }

  @override
  Future<Selection?> selection(String requestId) async {
    final j = await api.get<Object?>('/api/v1/requests/$requestId/selection');
    return j is Map ? _selection(j.cast<String, dynamic>()) : null;
  }

  @override
  Future<Offer?> noReply(String requestId) async {
    final orderId = _orders[requestId] ?? (await selection(requestId))?.orderId;
    if (orderId == null) return null;
    final j = await api.post<Map<String, dynamic>>(
      '/api/v1/orders/$orderId/no-reply',
    );
    _orders.remove(requestId);
    final next = j.om('next');
    return next == null ? null : offerFromJson(next);
  }

  @override
  Future<void> setHidden(String offerId, bool hidden) =>
      api.post<void>('/api/v1/offers/$offerId/${hidden ? 'hide' : 'unhide'}');

  Selection _selection(Map<String, dynamic> j) {
    final s = Selection(
      requestId: j.s('requestId'),
      orderId: j.s('orderId'),
      orderNo: j.s('orderNo'),
      itemTitle: j.s('itemTitle'),
      offer: offerFromJson(j.m('offer')),
      selectedAt: j.t('selectedAt'),
      pagePhone: (j.os('pagePhone') ?? '').replaceAll('+', ''),
      storeOrderId: j.os('storeOrderId'),
      noReplyAfter: Duration(seconds: j.i('noReplyAfterSec')),
    );
    _orders[s.requestId] = s.orderId;
    return s;
  }
}

Offer offerFromJson(Map<String, dynamic> o) => Offer(
  id: o.s('id'),
  pageId: o.s('pageId'),
  pageName: o.s('pageName'),
  image: o.os('image') ?? '',
  price: o.i('price'),
  rating: o.d('rating'),
  deals: o.i('deals'),
  trusted: o.b('trusted'),
  delivery: OfferStrings.deliveryFor(o.i('deliveryHours')),
  deliveryHours: o.i('deliveryHours'),
  replyMinutes: 0,
  condition: o.s('condition'),
  note: o.s('note'),
  photoStamp: o.s('photoStamp'),
  sponsored: o.b('sponsored'),
  hidden: o.b('hidden'),
);
