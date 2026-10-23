import 'package:dio/dio.dart';
import 'package:dawwerli/core/api/api_client.dart';
import 'package:dawwerli/features/orders/data/my_requests_provider.dart';
import 'package:dawwerli/features/orders/presentation/my_requests_screen.dart';
import 'package:dawwerli/features/seller/domain/seller_models.dart';
import 'package:dawwerli/features/seller/presentation/my_offers_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// GET /api/v1/requests/mine after the customer chose an offer.
class _Api implements ApiClient {
  _Api(this.rows);
  final List<Map<String, dynamic>> rows;

  @override
  Future<T> get<T>(
    String path, {
    Map<String, Object?>? query,
    CancelToken? cancelToken,
  }) async {
    expect(path, '/api/v1/requests/mine');
    return rows as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _row(
  String id,
  String status, {
  String? orderId,
  String? storeOrderId,
}) => {
  'id': id,
  'number': 1,
  'title': 'قميص أبيض',
  'image': null,
  'status': status,
  'offersCount': 1,
  'maxOffers': 5,
  'createdAt': '2026-10-23T10:00:00Z',
  'orderId': orderId,
  'storeOrderId': storeOrderId,
};

RequestSummary _summary(
  String status, {
  String? orderId,
  String? storeOrderId,
}) => RequestSummary(
  id: 'r1',
  title: 't',
  image: '',
  status: status,
  offers: 1,
  maxOffers: 5,
  createdAt: DateTime(2026),
  orderId: orderId,
  storeOrderId: storeOrderId,
);

SellerOffer _offer(OfferState state, {String? storeOrderId}) => SellerOffer(
  id: 'of1',
  requestId: 'r1',
  title: 't',
  image: '',
  price: 40000,
  state: state,
  storeOrderId: storeOrderId,
);

void main() {
  group('customer «طلباتي»', () {
    test('a chosen offer with a store order opens the order details', () {
      expect(
        requestRoute(_summary('selected', orderId: 'd1', storeOrderId: 's1')),
        '/store/orders/s1',
      );
      expect(
        requestRoute(_summary('closed', orderId: 'd1', storeOrderId: 's1')),
        '/store/orders/s1',
      );
    });

    test('requests without an order keep their old screens', () {
      expect(requestRoute(_summary('open')), '/requests/r1/live');
      expect(requestRoute(_summary('expired')), '/requests/r1/no-offers');
      expect(requestRoute(_summary('selected')), '/requests/r1/offers');
      expect(requestRoute(_summary('selected', orderId: 'd1')), '/orders/d1');
    });

    test('reads storeOrderId from GET /requests/mine', () async {
      final c = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(
            _Api([_row('r1', 'selected', orderId: 'd1', storeOrderId: 's1')]),
          ),
        ],
      );
      addTearDown(c.dispose);
      final rows = await c.read(myRequestsProvider.future);
      expect(rows.single.orderId, 'd1');
      expect(rows.single.storeOrderId, 's1');
    });

    testWidgets('tapping the accepted request opens the store order', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: '/requests',
        routes: [
          GoRoute(
            path: '/requests',
            builder: (_, _) => const MyRequestsScreen(),
          ),
          GoRoute(
            path: '/store/orders/:id',
            builder: (_, s) => Text('store order ${s.pathParameters['id']}'),
          ),
          GoRoute(
            path: '/orders/:id',
            builder: (_, s) => Text('old deal ${s.pathParameters['id']}'),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(
              _Api([_row('r1', 'selected', orderId: 'd1', storeOrderId: 's1')]),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('قميص أبيض'));
      await tester.pumpAndSettle();
      expect(find.text('store order s1'), findsOneWidget);
      expect(find.textContaining('old deal'), findsNothing);
    });
  });

  group('page «عروضي»', () {
    test('an accepted offer with a store order opens the order details', () {
      expect(
        sellerOfferRoute(_offer(OfferState.chosen, storeOrderId: 's1')),
        '/seller/orders/s1',
      );
    });

    test('unchosen offers keep the offer screens', () {
      expect(
        sellerOfferRoute(_offer(OfferState.waiting)),
        '/seller/offers/of1/view',
      );
      expect(sellerOfferRoute(_offer(OfferState.chosen)), '/seller/offers/of1');
    });
  });
}
