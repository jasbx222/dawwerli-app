/// Paid ad shown under a live request (always labelled «إعلان · مُموّل»).
class SponsoredPage {
  const SponsoredPage({
    required this.pageId,
    required this.name,
    required this.tagline,
    required this.image,
  });
  final String pageId;
  final String name;
  final String tagline;
  final String image;
}

/// A published request while it collects offers (10).
class LiveRequest {
  const LiveRequest({
    required this.id,
    required this.title,
    required this.image,
    required this.maxPrice,
    required this.reachedPages,
    required this.seenBy,
    required this.offerPrices,
    this.maxOffers = 5,
    required this.widensIn,
    this.widenedTo = const [],
    this.waitedMinutes = 0,
    this.suggestedPrice,
    this.sponsored,
  });

  final String id;
  final String title;
  final String image;
  final int maxPrice;
  final int reachedPages;
  final int seenBy;

  /// Offer prices in arrival order (first 5 verified pages only).
  final List<int> offerPrices;
  final int maxOffers;

  /// Time until the request widens to neighbouring governorates.
  final Duration widensIn;

  /// Set once the request was widened (10c sheet).
  final List<String> widenedTo;
  final int waitedMinutes;

  /// Price the server suggests raising to when no offers arrive.
  final int? suggestedPrice;
  final SponsoredPage? sponsored;

  int get cheapestIndex {
    if (offerPrices.isEmpty) return -1;
    var i = 0;
    for (var j = 1; j < offerPrices.length; j++) {
      if (offerPrices[j] < offerPrices[i]) i = j;
    }
    return i;
  }
}

/// Mirrors GET /v1/requests/{id}/live (SSE), POST /v1/requests/{id}/cancel,
/// PATCH /v1/requests/{id} {max_price}.
abstract interface class LiveRequestRepository {
  Stream<LiveRequest> watch(String id);
  Future<void> cancel(String id);
  Future<void> raisePrice(String id, int newMax);
}
