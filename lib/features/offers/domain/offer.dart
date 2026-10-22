/// One fixed-price offer from a verified page (GET /v1/requests/{id}/offers).
class Offer {
  const Offer({
    required this.id,
    required this.pageId,
    required this.pageName,
    required this.image,
    required this.price,
    required this.rating,
    required this.deals,
    required this.trusted,
    required this.delivery,
    required this.deliveryHours,
    required this.replyMinutes,
    required this.condition,
    required this.note,
    required this.photoStamp,
    this.sponsored = false,
    this.hidden = false,
  });

  final String id;
  final String pageId;
  final String pageName;

  /// In-app camera photo (watermarked server-side).
  final String image;

  /// Final price incl. delivery (locked).
  final int price;
  final double rating;

  /// Confirmed in-app deals.
  final int deals;

  /// «موثوقة» badge (deals ≥ admin threshold).
  final bool trusted;

  /// Delivery duration as written by the page, e.g. «يومين».
  final String delivery;
  final int deliveryHours;
  final int replyMinutes;
  final String condition;
  final String note;

  /// Watermark caption, e.g. «ستايل بغداد · 19/10 9:42 م» (camera icon drawn after it).
  final String photoStamp;

  /// «مُموّل»: pinned first, max one per request.
  final bool sponsored;

  /// Hidden by me (still counts toward the 5).
  final bool hidden;
}

enum OfferSort { cheapest, topRated, fastest }

class OffersBoard {
  const OffersBoard({
    required this.requestId,
    required this.offers,
    this.maxOffers = 5,
  });

  final String requestId;
  final List<Offer> offers;
  final int maxOffers;

  Offer? get cheapest => offers.isEmpty
      ? null
      : offers.reduce((a, b) => b.price < a.price ? b : a);

  /// Sponsored offer stays pinned first; the rest follow [sort].
  List<Offer> sorted(OfferSort sort) {
    final rest = offers.where((o) => !o.sponsored).toList()
      ..sort(switch (sort) {
        OfferSort.cheapest => (a, b) => a.price.compareTo(b.price),
        OfferSort.topRated => (a, b) => b.rating.compareTo(a.rating),
        OfferSort.fastest => (a, b) => a.deliveryHours.compareTo(
          b.deliveryHours,
        ),
      });
    return [...offers.where((o) => o.sponsored).take(1), ...rest];
  }

  Offer? byId(String id) {
    for (final o in offers) {
      if (o.id == id) return o;
    }
    return null;
  }
}

/// The single active selection on a request (order InPurchase).
class Selection {
  const Selection({
    required this.requestId,
    required this.orderId,
    required this.orderNo,
    required this.itemTitle,
    required this.offer,
    required this.selectedAt,
    required this.pagePhone,
    this.storeOrderId,
    this.noReplyAfter = const Duration(hours: 1),
  });

  final String requestId;
  final String orderId;
  final String orderNo;
  final String itemTitle;
  final Offer offer;
  final DateTime selectedAt;

  /// Page contact number (E.164 without +). Not used for chat: everything
  /// runs through the in-app order.
  final String pagePhone;

  /// The in-app order the page delivers through (status, courier, pin).
  final String? storeOrderId;

  /// Settings.NoReplyMinutes.
  final Duration noReplyAfter;
}

/// Where to deliver a chosen offer; sent once with the selection.
class SelectDelivery {
  const SelectDelivery({
    this.address,
    this.latitude,
    this.longitude,
    this.note,
  });
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? note;

  Map<String, Object?> toJson() => {
    if (address?.isNotEmpty == true) 'address': address,
    'latitude': ?latitude,
    'longitude': ?longitude,
    if (note?.isNotEmpty == true) 'locationNote': note,
  };
}

class SelectionConflict implements Exception {
  const SelectionConflict();
}

/// Mirrors GET /v1/requests/{id}/offers, POST /v1/requests/{id}/select {offerId},
/// POST /v1/requests/{id}/no-reply (releases the page fee, adds a no-reply mark).
abstract interface class OffersRepository {
  Future<OffersBoard> offers(String requestId);

  /// Throws [SelectionConflict] if another offer is already selected.
  Future<Selection> select(
    String requestId,
    String offerId, [
    SelectDelivery? delivery,
  ]);
  Future<Selection?> selection(String requestId);

  /// Drops the silent page and returns the next best offer (or null).
  Future<Offer?> noReply(String requestId);

  /// 47 · hide/unhide an offer on my board.
  Future<void> setHidden(String offerId, bool hidden);
}
