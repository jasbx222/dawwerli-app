import '../../../core/mock/mock_backend.dart';
import '../domain/live_request.dart';

const _img = 'assets/images/mock';

class MockLiveRequestRepository implements LiveRequestRepository {
  const MockLiveRequestRepository(this.backend, {this.widened = false});

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
      offerPrices: widened ? const [] : r.offerPrices,
      widensAt: r.widensAt,
      widenedTo: widened ? const ['بابل', 'ديالى', 'الأنبار'] : const [],
      waitedMinutes: widened ? 15 : 0,
      suggestedPrice: widened ? 55000 : null,
      sponsored: _sponsor,
      cancelled: r.status == MockRequestStatus.cancelled,
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
  Future<void> raisePrice(String id, int newMax) async =>
      backend.raisePrice(id, newMax);
}
