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

  /// Watermark caption, e.g. «ستايل بغداد · 19/10 9:42 م 📷».
  final String photoStamp;

  /// «مُموّل»: pinned first, max one per request.
  final bool sponsored;
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
    required this.orderNo,
    required this.itemTitle,
    required this.offer,
    required this.selectedAt,
    required this.pagePhone,
    this.noReplyAfter = const Duration(hours: 1),
  });

  final String requestId;
  final String orderNo;
  final String itemTitle;
  final Offer offer;
  final DateTime selectedAt;

  /// Page WhatsApp number (E.164 without +), revealed by the server on select.
  final String pagePhone;

  /// Settings.NoReplyMinutes.
  final Duration noReplyAfter;
}

class SelectionConflict implements Exception {
  const SelectionConflict();
}

/// Mirrors GET /v1/requests/{id}/offers, POST /v1/requests/{id}/select {offerId},
/// POST /v1/requests/{id}/no-reply (releases the page fee, adds a no-reply mark).
abstract interface class OffersRepository {
  Future<OffersBoard> offers(String requestId);

  /// Throws [SelectionConflict] if another offer is already selected.
  Future<Selection> select(String requestId, String offerId);
  Future<Selection?> selection(String requestId);

  /// Drops the silent page and returns the next best offer (or null).
  Future<Offer?> noReply(String requestId);
}
