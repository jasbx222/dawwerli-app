import '../../../core/api/api_client.dart';
import '../domain/order.dart';

/// GET /orders/{id}, POST /orders/{id}/delivery-answer, POST /orders/{id}/rating.
class ApiOrdersRepository implements OrdersRepository {
  ApiOrdersRepository(this.api);
  final ApiClient api;

  static const _alreadyRated = 'rating.exists';
  List<String> _tags = const [];
  List<String> _lowTags = const [];

  @override
  Future<OrderStatus> order(String id) async {
    final j = await api.get<Map<String, dynamic>>('/api/v1/orders/$id');
    _tags = j.list<String>('ratingTags');
    _lowTags = j.list<String>('lowRatingTags');
    final r = j.om('rating');
    final a = j.os('answer');
    return OrderStatus(
      id: j.s('id'),
      orderNo: j.s('orderNo'),
      pageId: j.s('pageId'),
      pageName: j.s('pageName'),
      pageImage: j.os('pageImage') ?? '',
      steps: [
        for (final s in j.l('steps'))
          OrderStep(title: s.s('title'), detail: s.s('detail'), done: s.b('done')),
      ],
      received: j.b('received'),
      storeOrderId: j.os('storeOrderId'),
      answer: DeliveryAnswer.values.where((v) => v.name == a).firstOrNull,
      rating: r == null
          ? null
          : Rating(
              stars: r.i('stars'),
              tags: r.list<String>('tags').toSet(),
              comment: r.os('comment') ?? '',
            ),
    );
  }

  @override
  Future<void> answer(String id, DeliveryAnswer a) =>
      api.post<void>('/api/v1/orders/$id/delivery-answer', {'answer': a.name});

  @override
  Future<void> rate(String id, Rating r) async {
    try {
      await api.post<void>('/api/v1/orders/$id/rating', {
        'stars': r.stars,
        'tags': r.tags.toList(),
        'comment': r.comment,
      });
    } on ApiException catch (e) {
      if (e.code == _alreadyRated) throw const AlreadyRated();
      rethrow;
    }
  }

  @override
  List<String> get ratingTags => _tags;

  @override
  List<String> get lowRatingTags => _lowTags;
}
