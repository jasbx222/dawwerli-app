import '../domain/order.dart';

class MockOrdersRepository implements OrdersRepository {
  MockOrdersRepository();

  bool _received = false;
  Rating? _rating;
  DeliveryAnswer? _answer;
  String _receivedAt = '';

  /// Design QA: the next rating send fails (network).
  bool failNext = false;

  /// Design QA: pretend the order was already received / rated.
  void seed({bool received = false, Rating? rating, DeliveryAnswer? answer}) {
    _received = received || rating != null || answer == DeliveryAnswer.received;
    _rating = rating;
    _answer = answer ?? (_received ? DeliveryAnswer.received : null);
    if (_received) _receivedAt = '21/10 · 4:15 م';
  }

  @override
  List<String> get ratingTags => const [
    'نفس الصورة',
    'توصيل سريع',
    'تعامل حلو',
    'تغليف',
  ];

  @override
  List<String> get lowRatingTags => const [
    'مو نفس الصورة',
    'تأخر',
    'تعامل',
    'تغليف',
  ];

  static String _stamp(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '${t.day}/${t.month} · $h:$m ${t.hour < 12 ? 'ص' : 'م'}';
  }

  @override
  Future<OrderStatus> order(String id) async => OrderStatus(
    id: id,
    orderNo: 'DW-20481',
    pageName: 'ستايل بغداد',
    pageImage: 'assets/images/mock/cat_shoes_1.webp',
    received: _received,
    rating: _rating,
    answer: _answer,
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
      OrderStep(title: 'استلمت', detail: _receivedAt, done: _received),
    ],
  );

  @override
  Future<void> answer(String id, DeliveryAnswer a) async {
    _answer = a;
    if (a == DeliveryAnswer.received) {
      _received = true;
      _receivedAt = _stamp(DateTime.now());
    }
  }

  @override
  Future<void> rate(String id, Rating r) async {
    if (_rating != null) throw const AlreadyRated();
    if (failNext) {
      failNext = false;
      throw Exception('network');
    }
    _rating = r;
  }
}
