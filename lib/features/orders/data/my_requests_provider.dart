import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

/// One row of «طلباتي» (GET /api/v1/requests/mine).
class RequestSummary {
  const RequestSummary({
    required this.id,
    required this.title,
    required this.image,
    required this.status,
    required this.offers,
    required this.maxOffers,
    required this.createdAt,
    this.orderId,
    this.storeOrderId,
  });
  final String id;
  final String title;
  final String image;

  /// Server status: open · expanded · locked · selected · closed · expired · cancelled.
  final String status;
  final int offers;
  final int maxOffers;
  final DateTime createdAt;
  final String? orderId;

  /// The store order (kind=offer) the chosen offer became, if any.
  final String? storeOrderId;

  bool get isOpen => const {'open', 'expanded', 'locked'}.contains(status);
}

final myRequestsProvider = FutureProvider.autoDispose<List<RequestSummary>>((ref) async {
  final list = asList(await ref.watch(apiClientProvider).get<List<dynamic>>('/api/v1/requests/mine'));
  return [
    for (final r in list)
      RequestSummary(
        id: r.s('id'),
        title: r.s('title'),
        image: r.os('image') ?? '',
        status: r.s('status'),
        offers: r.i('offersCount'),
        maxOffers: r.i('maxOffers'),
        createdAt: r.t('createdAt'),
        orderId: r.os('orderId'),
        storeOrderId: r.os('storeOrderId'),
      ),
  ];
});
