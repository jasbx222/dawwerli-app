import 'package:dawwerli/core/api/api_client.dart';
import 'package:dawwerli/core/storage/prefs.dart';
import 'package:dawwerli/core/widgets/app_page.dart';
import 'package:dawwerli/features/store/data/page_search_data.dart';
import 'package:dawwerli/features/store/presentation/page_search.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A small page catalog filtered like the API does it.
class _Api implements ApiClient {
  _Api([List<Map<String, Object?>>? products]) : products = products ?? _demo;
  final List<Map<String, Object?>> products;
  final searches = <Map<String, Object?>>[];
  final counts = <Map<String, Object?>>[];

  static final _demo = [
    _p('a', 'آيفون 15 برو', 1450000, 1, 'موبايلات'),
    _p('b', 'كفر ايفون شفاف', 15000, 3, 'اكسسوارات'),
    _p('c', 'شاشة سامسونج 55', 650000, 2, 'شاشات'),
    _p('d', 'ايربودز برو', 250000, 3, 'اكسسوارات', stock: 0),
  ];

  static Map<String, Object?> _p(
    String id,
    String name,
    int price,
    int cat,
    String catName, {
    int stock = 5,
  }) => {
    'id': id,
    'name': name,
    'price': price,
    'stock': stock,
    'pageId': 'pg',
    'categoryId': cat,
    'categoryName': catName,
  };

  @override
  Future<T> get<T>(
    String path, {
    Map<String, Object?>? query,
    CancelToken? cancelToken,
  }) async {
    if (path == '/api/v1/favorites') return <dynamic>[] as T;
    if (path == '/api/v1/pages/pg/product-facets') {
      return {
        'total': products.length,
        'inStock': products.where((p) => (p['stock'] as int) > 0).length,
        'minPrice': products.isEmpty ? null : 15000,
        'maxPrice': products.isEmpty ? null : 1450000,
        'categories': [
          {'id': 1, 'slug': 'phones', 'name': 'موبايلات', 'count': 1},
          {'id': 2, 'slug': 'tvs', 'name': 'شاشات', 'count': 1},
          {'id': 3, 'slug': 'accessories', 'name': 'اكسسوارات', 'count': 2},
        ],
      } as T;
    }
    expect(path, '/api/v1/pages/pg/products');
    final q = query!;
    (q['pageSize'] == 1 ? counts : searches).add(q);
    final text = ArabicFold.normalize(q['q'] as String? ?? '');
    final cats = (q['categoryIds'] as String?)?.split(',').map(int.parse);
    final hits = [
      for (final p in products)
        if (ArabicFold.normalize(p['name'] as String).contains(text) &&
            (cats == null || cats.contains(p['categoryId'])) &&
            (q['minPrice'] == null ||
                (p['price'] as int) >= (q['minPrice'] as int)) &&
            (q['maxPrice'] == null ||
                (p['price'] as int) <= (q['maxPrice'] as int)) &&
            (q['inStock'] != true || (p['stock'] as int) > 0))
          p,
    ];
    final page = q['page'] as int;
    final size = q['pageSize'] as int;
    return {
      'items': hits.skip((page - 1) * size).take(size).toList(),
      'page': page,
      'pageSize': size,
      'total': hits.length,
    } as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _open(WidgetTester t, _Api api) async {
  t.view.physicalSize = const Size(824, 1830);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        apiClientProvider.overrideWithValue(api),
      ],
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Consumer(
            builder: (context, ref, _) => AppPage(
              title: 'منتجات',
              endDrawer: const PageFilterDrawer(pageId: 'pg'),
              onNearEnd: () => loadMorePageProducts(ref, 'pg'),
              children: const [PageProductsSection(pageId: 'pg')],
            ),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

Finder _name(String s) =>
    find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText() == s);

void main() {
  testWidgets('typing searches once after the pause and marks the match', (
    t,
  ) async {
    final api = _Api();
    await _open(t, api);
    expect(find.text('4 منتجات · 1 نفدت كميتها'), findsOneWidget);
    expect(api.searches, hasLength(1));

    final field = find.byKey(const ValueKey('page-search-field'));
    await t.enterText(field, 'ا');
    await t.pump(const Duration(milliseconds: 100));
    await t.enterText(field, 'اي');
    await t.pump(const Duration(milliseconds: 100));
    await t.enterText(field, 'ايفون');
    await t.pump(const Duration(milliseconds: 299));
    expect(api.searches, hasLength(1), reason: 'still typing');
    await t.pump(const Duration(milliseconds: 1));
    await t.pumpAndSettle();
    expect(api.searches, hasLength(2));
    expect(api.searches.last['q'], 'ايفون');

    expect(_name('آيفون 15 برو'), findsOneWidget);
    expect(_name('كفر ايفون شفاف'), findsOneWidget);
    expect(_name('شاشة سامسونج 55'), findsNothing);
    expect(find.textContaining('2 منتجين'), findsOneWidget);
    // «ايفون» marks «آيفون».
    final rich = t.widget<RichText>(_name('آيفون 15 برو'));
    final marked = <String>[];
    rich.text.visitChildren((s) {
      if (s is TextSpan && s.style?.backgroundColor != null) {
        marked.add(s.text!);
      }
      return true;
    });
    expect(marked, ['آيفون']);

    await t.tap(find.byKey(const ValueKey('page-search-clear')));
    await t.pumpAndSettle();
    expect(find.text('4 منتجات · 1 نفدت كميتها'), findsOneWidget);
  });

  testWidgets('no match by name offers to clear the search', (t) async {
    await _open(t, _Api());
    await t.enterText(find.byKey(const ValueKey('page-search-field')), 'ثلاجة');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await t.pumpAndSettle();
    expect(find.text('ما لكينا منتج بهذا الاسم'), findsOneWidget);
    await t.tap(find.text('امسح البحث').last);
    await t.pumpAndSettle();
    expect(find.text('4 منتجات · 1 نفدت كميتها'), findsOneWidget);
  });

  testWidgets('drawer: live count, close drops the draft, apply filters', (
    t,
  ) async {
    final api = _Api();
    await _open(t, api);
    await t.tap(find.byKey(const ValueKey('page-filter-button')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('page-filter-drawer')), findsOneWidget);
    expect(find.text('طبّق · 4 منتجات'), findsOneWidget);

    await t.tap(find.text('اكسسوارات'));
    await t.pump();
    expect(find.text('طبّق'), findsOneWidget, reason: 'count is stale');
    await t.pump(const Duration(milliseconds: 300));
    await t.pumpAndSettle();
    expect(find.text('طبّق · 2 منتجين'), findsOneWidget);
    expect(api.counts.last['categoryIds'], '3');
    expect(api.counts.last['pageSize'], 1);

    // Close without applying: nothing changes, the draft is gone.
    await t.tap(find.bySemanticsLabel('سكّر'));
    await t.pumpAndSettle();
    expect(find.text('4 منتجات · 1 نفدت كميتها'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('page-filter-button')));
    await t.pumpAndSettle();
    expect(find.text('طبّق · 4 منتجات'), findsOneWidget);

    await t.tap(find.text('اكسسوارات'));
    await t.ensureVisible(find.byKey(const ValueKey('page-filter-stock')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('page-filter-stock')));
    await t.pump(const Duration(milliseconds: 300));
    await t.pumpAndSettle();
    expect(find.text('طبّق · 1 منتج'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('page-filter-apply')));
    await t.pumpAndSettle();

    expect(find.byKey(const ValueKey('page-filter-drawer')), findsNothing);
    expect(api.searches.last['categoryIds'], '3');
    expect(api.searches.last['inStock'], true);
    expect(_name('كفر ايفون شفاف'), findsOneWidget);
    expect(_name('ايربودز برو'), findsNothing);
    expect(find.bySemanticsLabel('الفلاتر (2)'), findsOneWidget);
    expect(find.text('اكسسوارات'), findsWidgets); // its chip
    expect(find.text('متوفر فقط'), findsOneWidget);

    // Dropping one chip keeps the other.
    await t.tap(find.bySemanticsLabel('شيل متوفر فقط'));
    await t.pumpAndSettle();
    expect(find.bySemanticsLabel('الفلاتر (1)'), findsOneWidget);
    expect(_name('ايربودز برو'), findsOneWidget);
  });

  testWidgets('no match by filters offers to clear them', (t) async {
    await _open(t, _Api());
    await t.tap(find.byKey(const ValueKey('page-filter-button')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('price-min')), '٢٠٠٠٠٠٠');
    await t.tap(find.byKey(const ValueKey('page-filter-apply')));
    await t.pumpAndSettle();
    expect(find.text('ماكو منتج يطابق الفلاتر'), findsOneWidget);
    expect(find.text('من 2 مليون'), findsOneWidget);
    await t.tap(find.text('مسح الفلاتر'));
    await t.pumpAndSettle();
    expect(find.text('4 منتجات · 1 نفدت كميتها'), findsOneWidget);
    expect(find.bySemanticsLabel('الفلاتر'), findsOneWidget);
  });

  testWidgets('«مسح الكل» in the drawer resets the whole draft', (t) async {
    final api = _Api();
    await _open(t, api);
    await t.tap(find.byKey(const ValueKey('page-filter-button')));
    await t.pumpAndSettle();
    await t.tap(find.text('شاشات'));
    await t.tap(find.text('أقل من 250 ألف'));
    await t.pump(const Duration(milliseconds: 300));
    await t.pumpAndSettle();
    expect(find.text('طبّق · 0 منتج'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('page-filter-reset')));
    await t.pump(const Duration(milliseconds: 300));
    await t.pumpAndSettle();
    expect(find.text('طبّق · 4 منتجات'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('page-filter-apply')));
    await t.pumpAndSettle();
    expect(find.bySemanticsLabel('الفلاتر'), findsOneWidget);
    expect(api.searches.last.containsKey('categoryIds'), isFalse);
  });

  testWidgets('a page with no products has no search bar', (t) async {
    await _open(t, _Api([]));
    expect(find.text('ماكو منتجات بعد'), findsOneWidget);
    expect(find.byKey(const ValueKey('page-search-field')), findsNothing);
  });

  testWidgets('long lists load the next page near the end', (t) async {
    final api = _Api([
      for (var i = 0; i < 45; i++)
        _Api._p('p$i', 'منتج $i', 1000 + i, 1, 'موبايلات'),
    ]);
    await _open(t, api);
    expect(api.searches, hasLength(1));
    await t.drag(find.byType(ListView).first, const Offset(0, -6000));
    await t.pumpAndSettle();
    await t.drag(find.byType(ListView).first, const Offset(0, -9000));
    await t.pumpAndSettle();
    expect(api.searches.map((q) => q['page']), [1, 2, 3]);
    expect(_name('منتج 44'), findsOneWidget);
  });
}
