import 'dart:convert';

import 'package:dawwerli/features/offers/data/api_offers_repository.dart';
import 'package:dawwerli/features/offers/data/offers_providers.dart';
import 'package:dawwerli/features/offers/domain/offer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Server stand-in: pages add offers while the customer's screens are open.
class _Server implements OffersRepository {
  final sent = <Offer>[];
  int reads = 0;

  @override
  Future<OffersBoard> offers(String requestId) async {
    reads++;
    return OffersBoard(requestId: requestId, offers: List.of(sent));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Offer _offer(String id) => Offer(
  id: id,
  pageId: 'p-$id',
  pageName: 'صفحة $id',
  image: '',
  price: 40000,
  rating: 4.5,
  deals: 3,
  trusted: false,
  delivery: 'يوم',
  deliveryHours: 24,
  replyMinutes: 0,
  condition: 'new',
  note: '',
  photoStamp: '',
);

void main() {
  const id = 'req-1';

  ProviderContainer container(_Server server, Duration poll) {
    final c = ProviderContainer(
      overrides: [
        offersRepositoryProvider.overrideWithValue(server),
        offersPollProvider.overrideWithValue(poll),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test(
    'an offer sent after home cached the board reaches the compare screen',
    () async {
      final server = _Server();
      final c = container(server, const Duration(hours: 1));

      // Home loads the board before any page has answered, then gets covered.
      final home = c.listen(offersProvider(id), (_, _) {});
      expect((await c.read(offersProvider(id).future)).offers, isEmpty);
      home.pause();

      server.sent.add(_offer('o1'));

      // Compare (or details) opens on top of home: it must see the new offer.
      final compare = c.listen(offersProvider(id), (_, _) {});
      await Future<void>.delayed(Duration.zero);
      final board = await c.read(offersProvider(id).future);
      expect(board.byId('o1'), isNotNull);
      expect(server.reads, 2);
      compare.close();
    },
  );

  test('an open board picks up new offers on its own', () async {
    final server = _Server();
    final c = container(server, const Duration(milliseconds: 20));
    final sub = c.listen(offersProvider(id), (_, _) {});
    expect((await c.read(offersProvider(id).future)).offers, isEmpty);

    server.sent.add(_offer('o1'));
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(sub.read().value?.byId('o1'), isNotNull);
  });

  test(
    'a covered board stops polling and refreshes when shown again',
    () async {
      final server = _Server();
      final c = container(server, const Duration(milliseconds: 20));
      final home = c.listen(offersProvider(id), (_, _) {});
      await c.read(offersProvider(id).future);
      home.pause();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final whilePaused = server.reads;
      expect(whilePaused, lessThanOrEqualTo(2));

      server.sent.add(_offer('o2'));
      home.resume();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(home.read().value?.byId('o2'), isNotNull);
    },
  );

  test('parses the board exactly as the API sends it', () {
    // Captured from GET /api/v1/requests/{id}/offers right after a page offered.
    final j = jsonDecode(
      '{"requestId":"b665946f","maxOffers":5,"offers":[{"id":"18670d9e",'
      '"pageId":"284eed9d","pageName":"p07700100001","image":null,"price":45000,'
      '"rating":0,"deals":0,"trusted":false,"deliveryHours":24,"condition":"new",'
      '"note":"","photoStamp":"p07700100001 · 2026-10-23 02:40","sponsored":false,'
      '"hidden":false,"createdAt":"2026-10-22T23:40:08.576285Z"}]}',
    ) as Map<String, dynamic>;
    final o = offerFromJson(
      (j['offers'] as List).single as Map<String, dynamic>,
    );
    expect(o.id, '18670d9e');
    expect(o.price, 45000);
    expect(o.rating, 0);
    expect(o.image, '');
  });
}
