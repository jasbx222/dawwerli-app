import '../../../core/mock/mock_backend.dart';
import '../domain/live_request.dart';

const _img = 'assets/images/mock';

class MockLiveRequestRepository implements LiveRequestRepository {
  const MockLiveRequestRepository(
    this.backend, {
    this.widened = false,
    this.expired = false,
    this.expiredOffers = false,
  });

  /// Mock the expired state (24h over), with or without earlier offers.
  final bool expired;
  final bool expiredOffers;

  final MockBackend backend;

  /// Mock the "15 minutes, no offers → widened" scenario (10c).
  final bool widened;

  static const _sponsor = SponsoredPage(
    pageId: 'p1',
    name: 'ستايل بغداد',
    tagline: 'أحذية رياضية أصلية · توصيل لبغداد',
    image: '$_img/cat_shoes_2.webp',
  );

  LiveRequest? _snapshot(String id) {
    final r = backend.requests[id];
    if (r == null) return null;
    return LiveRequest(
      id: id,
      title: r.title,
      image: r.image,
      maxPrice: r.maxPrice,
      reachedPages: 14,
      seenBy: 9,
      offerPrices: widened || (expired && !expiredOffers)
          ? const []
          : r.offerPrices,
      widensAt: r.widensAt,
      widenedTo: widened ? const ['بابل', 'ديالى', 'الأنبار'] : const [],
      waitedMinutes: widened ? 15 : 0,
      suggestedPrice: widened ? 55000 : null,
      sponsored: _sponsor,
      cancelled: r.status == MockRequestStatus.cancelled,
      expired: expired || backend.now().isAfter(r.closesAt),
    );
  }

  @override
  Stream<LiveRequest> watch(String id) async* {
    final first = _snapshot(id);
    if (first == null) throw StateError('unknown request $id');
    yield first;
    await for (final changed in backend.changes) {
      if (changed == id) yield _snapshot(id)!;
    }
  }

  @override
  Future<void> cancel(String id) async => backend.cancel(id);

  @override
  Future<String> republish(String id) async {
    final r = backend.requests[id]!;
    return backend
        .create(title: r.title, image: r.image, maxPrice: r.maxPrice)
        .id;
  }

  @override
  Future<void> raisePrice(String id, int newMax) async =>
      backend.raisePrice(id, newMax);
}
