import 'dart:async';

import 'package:dawwerli/core/api/api_client.dart';
import 'package:dawwerli/features/seller/data/page_store_orders.dart';
import 'package:dawwerli/features/tracking/courier_tracking.dart';
import 'package:dawwerli/features/tracking/tracking_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers the courier-location and tracking-link calls.
class _Api implements ApiClient {
  Map<String, dynamic> location = {'active': false};
  final calls = <String>[];

  @override
  Future<T> get<T>(String path, {Map<String, Object?>? query}) async {
    calls.add('GET $path');
    return location as T;
  }

  @override
  Future<T> post<T>(String path, [Object? body]) async {
    calls.add('POST $path');
    return {
      'url': 'https://dawwerli.iq/c/NEWTOKEN',
      'sharing': false,
      'lastLocationAt': null,
      'createdAt': '2026-10-23T10:00:00Z',
    } as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Pushes implements CourierPushes {
  final ctl = StreamController<CourierLocation>.broadcast();
  final watched = <String>[];

  @override
  Stream<CourierLocation> watch(String storeOrderId) {
    watched.add(storeOrderId);
    return ctl.stream;
  }
}

Map<String, dynamic> _active({int eta = 7}) => {
  'active': true,
  'latitude': 33.31,
  'longitude': 44.40,
  'updatedAt': DateTime.now().toUtc().toIso8601String(),
  'distanceMeters': 1800.0,
  'etaMinutes': eta,
  'approximate': true,
};

Widget _host(_Api api, _Pushes pushes, Widget child) => ProviderScope(
  overrides: [
    apiClientProvider.overrideWithValue(api),
    courierPushesProvider.overrideWithValue(pushes),
  ],
  child: MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  ),
);

void main() {
  group('parsing', () {
    test('courier location from the API', () {
      final l = CourierLocation.fromJson(_active());
      expect(l.active, isTrue);
      expect(l.hasPoint, isTrue);
      expect(l.latitude, 33.31);
      expect(l.etaMinutes, 7);
      expect(CourierLocation.fromJson({'active': false}).hasPoint, isFalse);
    });

    test('page order details carry the courier link', () {
      final o = PageStoreOrder.fromJson({
        'order': {'id': 's1', 'status': 'outForDelivery'},
        'customerName': 'أحمد',
        'courierTrackingUrl': 'https://dawwerli.iq/c/TOKEN',
        'courierTracking': {
          'url': 'https://dawwerli.iq/c/TOKEN',
          'sharing': true,
          'lastLocationAt': '2026-10-23T10:00:00Z',
        },
      });
      expect(o.trackingLink?.url, 'https://dawwerli.iq/c/TOKEN');
      expect(o.trackingLink?.sharing, isTrue);
      expect(o.trackingLink?.lastLocationAt, isNotNull);

      final bare = PageStoreOrder.fromJson({
        'order': {'id': 's1', 'status': 'outForDelivery'},
        'courierTrackingUrl': 'https://dawwerli.iq/c/T2',
      });
      expect(bare.trackingLink?.url, 'https://dawwerli.iq/c/T2');
      expect(bare.trackingLink?.sharing, isFalse);

      final none = PageStoreOrder.fromJson({
        'order': {'id': 's1', 'status': 'delivered'},
        'courierTrackingUrl': null,
      });
      expect(none.trackingLink, isNull);
    });

    test('ETA and last-update labels', () {
      expect(
        courierEtaLabel(CourierLocation.fromJson(_active(eta: 12))),
        'المندوب بالطريق · يوصل تقريباً خلال 12 دقيقة',
      );
      expect(
        courierEtaLabel(CourierLocation.fromJson(_active(eta: 1))),
        'المندوب بالطريق · يوصل تقريباً خلال دقيقة',
      );
      final now = DateTime(2026, 10, 23, 12);
      expect(
        courierUpdatedLabel(now.subtract(const Duration(seconds: 5)), now: now),
        'آخر تحديث هسه',
      );
      expect(
        courierUpdatedLabel(now.subtract(const Duration(minutes: 3)), now: now),
        'آخر تحديث قبل 3 دقيقة',
      );
    });
  });

  group('customer live courier', () {
    testWidgets(
      'hidden until sharing, then shows ETA from polling and pushes',
      (tester) async {
        final api = _Api();
        final pushes = _Pushes();
        await tester.pumpWidget(
          _host(
            api,
            pushes,
            const LiveCourierSection(
              storeOrderId: 's1',
              pinLatitude: 33.30,
              pinLongitude: 44.42,
            ),
          ),
        );
        await tester.pump();
        expect(api.calls, ['GET /api/v1/store/orders/s1/courier-location']);
        expect(pushes.watched, ['s1']);
        expect(find.textContaining('المندوب بالطريق'), findsNothing);

        // Courier pressed «ابدأ التوصيل»: the next poll picks it up.
        api.location = _active(eta: 9);
        await tester.pump(courierPollEvery);
        await tester.pump();
        expect(
          find.text('المندوب بالطريق · يوصل تقريباً خلال 9 دقيقة'),
          findsOneWidget,
        );
        expect(find.text('آخر تحديث هسه'), findsOneWidget);
        expect(find.bySemanticsLabel('المندوب'), findsOneWidget);

        // A live push moves the marker without waiting for the poll.
        pushes.ctl.add(CourierLocation.fromJson(_active(eta: 4)));
        await tester.pump();
        await tester.pump();
        expect(
          find.text('المندوب بالطريق · يوصل تقريباً خلال 4 دقيقة'),
          findsOneWidget,
        );

        // Courier stopped / order closed: block disappears.
        pushes.ctl.add(CourierLocation.inactive);
        await tester.pump();
        await tester.pump();
        expect(find.textContaining('المندوب بالطريق'), findsNothing);

        // Leaving the screen stops polling and the live subscription.
        await tester.pumpWidget(const SizedBox());
        final before = api.calls.length;
        await tester.pump(courierPollEvery * 3);
        expect(api.calls.length, before);
        expect(pushes.ctl.hasListener, isFalse);
      },
    );

    testWidgets('page side reads through the page endpoint', (tester) async {
      final api = _Api()..location = _active();
      await tester.pumpWidget(
        _host(
          api,
          _Pushes(),
          const LiveCourierSection(storeOrderId: 's9', forPage: true),
        ),
      );
      await tester.pump();
      expect(
        api.calls.first,
        'GET /api/v1/pages/me/store-orders/s9/courier-location',
      );
      expect(find.textContaining('يوصل تقريباً خلال 7 دقيقة'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('page courier link card', () {
    testWidgets('copy puts the link on the clipboard; new link asks first', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      final api = _Api();
      var link = const CourierTrackingLink(
        url: 'https://dawwerli.iq/c/OLDTOKEN',
        sharing: true,
      );
      await tester.pumpWidget(
        _host(
          api,
          _Pushes(),
          Consumer(
            builder: (context, ref, _) => StatefulBuilder(
              builder: (context, setState) => CourierLinkCard(
                link: link,
                onRegenerate: () async {
                  final l = await ref
                      .read(courierTrackingRepoProvider)
                      .regenerate('s1');
                  setState(() => link = l);
                },
              ),
            ),
          ),
        ),
      );
      expect(find.text('https://dawwerli.iq/c/OLDTOKEN'), findsOneWidget);
      expect(find.textContaining('المندوب يشارك موقعه'), findsOneWidget);
      expect(find.text('شارك'), findsOneWidget);

      await tester.tap(find.text('انسخ'));
      await tester.pump();
      expect(copied, 'https://dawwerli.iq/c/OLDTOKEN');

      // Cancelling keeps the old link.
      await tester.tap(find.text('رابط جديد'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('لا'));
      await tester.pumpAndSettle();
      expect(api.calls, isEmpty);

      await tester.tap(find.text('رابط جديد'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('سوّي رابط جديد'));
      await tester.pumpAndSettle();
      expect(api.calls, [
        'POST /api/v1/pages/me/store-orders/s1/tracking-link',
      ]);
      expect(find.text('https://dawwerli.iq/c/NEWTOKEN'), findsOneWidget);
      expect(find.textContaining('بعده ما بدأ التوصيل'), findsOneWidget);
    });
  });
}
