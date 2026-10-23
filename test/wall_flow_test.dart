import 'dart:ui' as ui;

import 'package:dawwerli/core/storage/prefs.dart';
import 'package:dawwerli/features/store/data/store_data.dart';
import 'package:dawwerli/features/wall/wall_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

StoreProduct tv() => StoreProduct.fromJson({
  'id': 'tv65',
  'name': 'شاشة سامسونج 65',
  'price': 900000,
  'stock': 4,
  'pageId': 'pg',
  'widthCm': 145,
  'heightCm': 83,
  'wallKind': 'tv',
  'variantLabel': '65 إنش',
  'variants': [
    {
      'id': 'tv55',
      'label': '55 إنش',
      'name': 'شاشة 55',
      'price': 650000,
      'stock': 0,
      'widthCm': 123,
      'heightCm': 71,
      'wallKind': 'tv',
    },
    {
      'id': 'tv65',
      'label': '65 إنش',
      'name': 'شاشة 65',
      'price': 900000,
      'stock': 4,
      'widthCm': 145,
      'heightCm': 83,
      'wallKind': 'tv',
    },
  ],
});

void main() {
  testWidgets('align → result, size switch updates price and stock', (t) async {
    t.view.physicalSize = const Size(1400, 2400);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final photo = await t.runAsync(() async {
      final r = ui.PictureRecorder();
      ui.Canvas(r).drawRect(
        const Rect.fromLTWH(0, 0, 1200, 900),
        ui.Paint()..color = const Color(0xFFE8E2D6),
      );
      return r.endRecording().toImage(1200, 900);
    });
    final p = tv();
    await t.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: WallFlow(
              product: p,
              pageId: 'pg',
              choices: wallChoices(p),
              initialPhoto: photo,
            ),
          ),
        ),
      ),
    );
    await t.pump();
    expect(find.text('طابق الزوايا'), findsOneWidget);
    await t.tap(find.text('تم'));
    await t.pumpAndSettle();
    expect(find.text('على حايطك'), findsOneWidget);
    expect(find.text('اطلبها'), findsOneWidget);
    expect(find.textContaining('900'), findsWidgets);

    await t.tap(find.textContaining('55 إنش').first);
    await t.pumpAndSettle();
    expect(find.text('نفدت'), findsWidgets);
    expect(find.text('اطلبها'), findsNothing);
    expect(find.textContaining('650'), findsWidgets);
    photo!.dispose();
  });

  test('entry hidden without a full size', () {
    final bare = StoreProduct.fromJson({'id': 'x', 'name': 'x', 'widthCm': 50});
    expect(bare.wall, isNull);
    expect(tv().wall, isNotNull);
    expect(wallChoices(tv()).map((v) => v.id), ['tv55', 'tv65']);
  });
}
