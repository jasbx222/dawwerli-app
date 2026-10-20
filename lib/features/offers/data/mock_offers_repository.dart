import '../domain/offer.dart';

const _img = 'assets/images/mock';

/// In-memory stand-in for the offers API (keeps state across 11 → 14).
class MockOffersRepository implements OffersRepository {
  MockOffersRepository({
    String? selectedOfferId,
    Duration selectedAgo = Duration.zero,
  }) {
    if (selectedOfferId != null) {
      _selected = selectedOfferId;
      _selectedAt = DateTime.now().subtract(selectedAgo);
    }
  }

  static const all = [
    Offer(
      id: 'o2',
      pageId: 'p2',
      pageName: 'رياضة الكرادة',
      image: '$_img/cat_shoes_2.webp',
      price: 39000,
      rating: 4.9,
      deals: 210,
      trusted: true,
      delivery: 'اليوم',
      deliveryHours: 8,
      replyMinutes: 4,
      condition: 'جديد، أصلي',
      note: 'جلد طبيعي مع الكارتون',
      photoStamp: 'رياضة الكرادة · 19/10 9:45 م 📷',
      sponsored: true,
    ),
    Offer(
      id: 'o1',
      pageId: 'p1',
      pageName: 'ستايل بغداد',
      image: '$_img/cat_shoes_1.webp',
      price: 35000,
      rating: 4.8,
      deals: 120,
      trusted: true,
      delivery: 'يومين',
      deliveryHours: 48,
      replyMinutes: 6,
      condition: 'جديد، أصلي',
      note: 'نايك أصلي مع الكارتون',
      photoStamp: 'ستايل بغداد · 19/10 9:42 م 📷',
    ),
    Offer(
      id: 'o3',
      pageId: 'p3',
      pageName: 'موبايل زون',
      image: '$_img/shop_2.webp',
      price: 42000,
      rating: 4.5,
      deals: 31,
      trusted: false,
      delivery: '3 أيام',
      deliveryHours: 72,
      replyMinutes: 12,
      condition: 'جديد',
      note: 'القياس 43 متوفر',
      photoStamp: 'موبايل زون · 19/10 9:51 م 📷',
    ),
  ];

  /// Design QA (`?preview=` on 14/14b): pretend [offerId] was chosen [ago].
  void seedSelection(String offerId, Duration ago) {
    _dropped.remove(offerId);
    _selected = offerId;
    _selectedAt = DateTime.now().subtract(ago);
  }

  final _dropped = <String>{};
  String? _selected;
  DateTime? _selectedAt;

  @override
  Future<OffersBoard> offers(String requestId) async => OffersBoard(
    requestId: requestId,
    offers: [
      for (final o in all)
        if (!_dropped.contains(o.id)) o,
    ],
  );

  @override
  Future<Selection> select(String requestId, String offerId) async {
    if (_selected != null && _selected != offerId) {
      throw const SelectionConflict();
    }
    if (_selected == null) {
      _selected = offerId;
      _selectedAt = DateTime.now();
    }
    return (await selection(requestId))!;
  }

  @override
  Future<Selection?> selection(String requestId) async {
    final id = _selected;
    if (id == null) return null;
    return Selection(
      requestId: requestId,
      orderNo: 'DW-20481',
      itemTitle: 'حذاء رياضي أسود 43',
      offer: all.firstWhere((o) => o.id == id),
      selectedAt: _selectedAt!,
      pagePhone: '9647701234567',
    );
  }

  @override
  Future<Offer?> noReply(String requestId) async {
    final id = _selected;
    if (id == null) return null;
    _dropped.add(id);
    _selected = null;
    _selectedAt = null;
    final next = (await offers(requestId)).sorted(OfferSort.cheapest);
    return next.isEmpty ? null : next.first;
  }
}
