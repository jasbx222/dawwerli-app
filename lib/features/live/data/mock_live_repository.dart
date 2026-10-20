import '../domain/live_request.dart';

const _img = 'assets/images/mock';

class MockLiveRequestRepository implements LiveRequestRepository {
  const MockLiveRequestRepository({this.widened = false});

  /// Mock the "15 minutes, no offers → widened" scenario (10c).
  final bool widened;

  static const _sponsor = SponsoredPage(
    pageId: 'p1',
    name: 'ستايل بغداد',
    tagline: 'أحذية رياضية أصلية · توصيل لبغداد',
    image: '$_img/cat_shoes_2.webp',
  );

  @override
  Stream<LiveRequest> watch(String id) async* {
    yield LiveRequest(
      id: id,
      title: 'حذاء رياضي أسود · 43',
      image: '$_img/cat_shoes_1.webp',
      maxPrice: 45000,
      reachedPages: 14,
      seenBy: 9,
      offerPrices: widened ? const [] : const [35000, 39000, 42000],
      widensIn: const Duration(minutes: 11, seconds: 20),
      widenedTo: widened ? const ['بابل', 'ديالى', 'الأنبار'] : const [],
      waitedMinutes: widened ? 15 : 0,
      suggestedPrice: widened ? 55000 : null,
      sponsored: _sponsor,
    );
  }

  @override
  Future<void> cancel(String id) async {}

  @override
  Future<void> raisePrice(String id, int newMax) async {}
}
