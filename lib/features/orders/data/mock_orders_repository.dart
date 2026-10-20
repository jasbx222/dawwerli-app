import '../domain/order.dart';

class MockOrdersRepository implements OrdersRepository {
  MockOrdersRepository();

  bool _received = false;
  Rating? _rating;

  /// Design QA: pretend the order was already received / rated.
  void seed({bool received = false, Rating? rating}) {
    _received = received || rating != null;
    _rating = rating;
  }

  @override
  List<String> get ratingTags => const [
    'نفس الصورة',
    'توصيل سريع',
    'تعامل حلو',
    'تغليف',
  ];

  @override
  Future<OrderStatus> order(String id) async => OrderStatus(
    id: id,
    orderNo: 'DW-20481',
    pageName: 'ستايل بغداد',
    pageImage: 'assets/images/mock/cat_shoes_1.webp',
    received: _received,
    rating: _rating,
    steps: [
      const OrderStep(
        title: 'اخترت العرض',
        detail: '19/10 · 9:42 م',
        done: true,
      ),
      const OrderStep(
        title: 'الصفحة تواصلت وياك',
        detail: '19/10 · 9:50 م',
        done: true,
      ),
      const OrderStep(title: 'بالطريق', detail: 'متوقع 21/10', done: true),
      OrderStep(title: 'استلمت', done: _received),
    ],
  );

  @override
  Future<void> answer(String id, DeliveryAnswer a) async {
    if (a == DeliveryAnswer.received) _received = true;
  }

  @override
  Future<void> rate(String id, Rating r) async {
    if (_rating != null) throw const AlreadyRated();
    _rating = r;
  }
}
