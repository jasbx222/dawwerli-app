import 'package:dawwerli/features/home/data/sponsored_popup_scheduler.dart';
import 'package:dawwerli/features/home/domain/sponsored_popup_ad.dart';
import 'package:dawwerli/features/home/presentation/widgets/sponsored_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SponsoredPopupAd ad(
  String id, {
  String image = 'assets/images/cat_phones_1.webp',
}) => SponsoredPopupAd(
  id: id,
  pageId: 'p-$id',
  pageName: 'صفحة $id',
  title: 'عرض $id',
  headline: 'نص',
  image: image,
  pageHandle: 'shop_$id',
);

const settings = PopupSettings(
  duration: Duration(seconds: 5),
  interval: Duration(minutes: 10),
  firstDelay: Duration(seconds: 3),
  maxPerAdPerDay: 0,
);

void main() {
  group('PopupSettings', () {
    test('reads server values, no app defaults', () {
      final s = PopupSettings.fromJson({
        'durationSec': 7,
        'intervalMin': 25,
        'firstDelaySec': 2,
        'maxPerAdPerDay': 4,
      })!;
      expect(s.duration, const Duration(seconds: 7));
      expect(s.interval, const Duration(minutes: 25));
      expect(s.firstDelay, const Duration(seconds: 2));
      expect(s.maxPerAdPerDay, 4);
      expect(PopupSettings.fromJson({'durationSec': 5}), isNull);
      expect(PopupSettings.fromJson(s.toJson())!.interval, s.interval);
    });
  });

  group('PopupClock', () {
    bool run(PopupClock c, int seconds, {bool allowed = true, bool fg = true}) {
      var due = false;
      for (var i = 0; i < seconds; i++) {
        due = c.tick(foreground: fg, allowed: allowed, settings: settings);
        if (due) return true;
      }
      return due;
    }

    test('first popup after the first delay on an allowed screen', () {
      final c = PopupClock(sinceLast: 1 << 30);
      expect(run(c, 2), isFalse);
      expect(run(c, 1), isTrue);
    });

    test('next popup only after 10 minutes of foreground time', () {
      final c = PopupClock()..shown();
      expect(run(c, 599), isFalse);
      expect(run(c, 1), isTrue);
    });

    test('background time does not count', () {
      final c = PopupClock()..shown();
      expect(run(c, 3600, fg: false), isFalse);
      expect(c.sinceLast, 0);
    });

    test('blocked screens wait, then the first delay applies again', () {
      final c = PopupClock()..shown();
      expect(run(c, 700, allowed: false), isFalse);
      expect(run(c, 2), isFalse);
      expect(run(c, 1), isTrue);
    });
  });

  group('rotation', () {
    final now = DateTime(2026, 10, 23, 12);

    test('least shown first, then least recent; no image is skipped', () {
      final h = PopupHistory()
        ..record('a', now)
        ..record('a', now)
        ..record('b', now.subtract(const Duration(minutes: 30)))
        ..record('c', now);
      final out = popupCandidates(
        [ad('a'), ad('b'), ad('c'), ad('d'), ad('e', image: '')],
        h,
        0,
        now,
      );
      expect(out.map((a) => a.id), ['d', 'b', 'c', 'a']);
    });

    test('daily cap per ad (0 = unlimited) resets the next day', () {
      final h = PopupHistory()
        ..record('a', now)
        ..record('a', now);
      expect(popupCandidates([ad('a')], h, 2, now), isEmpty);
      expect(popupCandidates([ad('a')], h, 0, now), hasLength(1));
      final tomorrow = now.add(const Duration(days: 1));
      expect(popupCandidates([ad('a')], h, 2, tomorrow), hasLength(1));
      final back = PopupHistory.decode(h.encode());
      expect(back.total('a'), 2);
    });
  });

  test('popup only on browsing screens', () {
    for (final p in ['/home', '/pages', '/pages/p/123', '/categories/x']) {
      expect(popupAllowedOn(p), isTrue, reason: p);
    }
    for (final p in ['/login', '/post', '/live', '/wallet', '/seller/home']) {
      expect(popupAllowedOn(p), isFalse, reason: p);
    }
  });

  group('SponsoredPopup widget', () {
    Future<(Future<PopupAction?>, List<String>)> open(WidgetTester t) async {
      final seen = <String>[];
      late Future<PopupAction?> result;
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => result = showSponsoredPopup(
                  context,
                  ad: ad('x'),
                  duration: const Duration(seconds: 5),
                  onSeen: () => seen.add('x'),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      return (result, seen);
    }

    final close = find.byKey(const Key('sponsored-popup-close'));

    testWidgets('X is a plain button that closes at once, no countdown', (
      t,
    ) async {
      final (result, seen) = await open(t);
      expect(close, findsOneWidget);
      for (final n in ['1', '2', '3', '4', '5']) {
        expect(find.text(n), findsNothing);
      }
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await t.tap(close);
      await t.pumpAndSettle();
      expect(close, findsNothing);
      expect(await result, isNull);
      expect(seen, isEmpty, reason: 'closed before 1 s: no impression');
    });

    testWidgets('impression after 1 s, auto-closes after the duration', (
      t,
    ) async {
      final (result, seen) = await open(t);
      await t.pump(const Duration(seconds: 1));
      expect(seen, ['x']);
      await t.pump(const Duration(seconds: 4));
      await t.pumpAndSettle();
      expect(close, findsNothing);
      expect(await result, isNull);
      expect(seen, hasLength(1));
    });

    testWidgets('CTA returns the action', (t) async {
      final (result, _) = await open(t);
      await t.tap(find.byKey(const Key('sponsored-popup-page')));
      await t.pumpAndSettle();
      expect(await result, PopupAction.page);
    });
  });
}
