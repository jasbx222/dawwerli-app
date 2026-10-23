enum DeliveryAnswer { received, notReceived, mismatch }

class OrderStep {
  const OrderStep({required this.title, this.detail = '', this.done = false});
  final String title;
  final String detail;
  final bool done;
}

/// Order after selection (InPurchase → AwaitingDelivery → Delivered → Rated).
class OrderStatus {
  const OrderStatus({
    required this.id,
    required this.orderNo,
    required this.pageId,
    required this.pageName,
    required this.pageImage,
    required this.steps,
    this.received = false,
    this.rating,
    this.answer,
    this.storeOrderId,
  });
  final String id;
  final String orderNo;
  final String pageId;
  final String pageName;
  final String pageImage;
  final List<OrderStep> steps;
  final bool received;
  final Rating? rating;
  final DeliveryAnswer? answer;

  /// The store order (kind=offer) this deal runs as; open that instead.
  final String? storeOrderId;
  bool get rated => rating != null;
}

class Rating {
  const Rating({required this.stars, required this.tags, this.comment = ''});
  final int stars;
  final Set<String> tags;
  final String comment;
}

class AlreadyRated implements Exception {
  const AlreadyRated();
}

/// Mirrors GET /v1/orders/{id}, POST /v1/orders/{id}/delivery-answer,
/// POST /v1/orders/{id}/rating (one per order, only after receipt).
abstract interface class OrdersRepository {
  Future<OrderStatus> order(String id);
  Future<void> answer(String id, DeliveryAnswer a);
  Future<void> rate(String id, Rating r);
  List<String> get ratingTags;

  /// Tags offered at ≤ 2 stars.
  List<String> get lowRatingTags;
}
