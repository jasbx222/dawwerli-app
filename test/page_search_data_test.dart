import 'package:dawwerli/core/api/api_client.dart';
import 'package:dawwerli/features/store/data/page_search_data.dart';
import 'package:dawwerli/features/store/presentation/page_search.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers the page products endpoint with [total] products, paged.
class _Api implements ApiClient {
  _Api({this.total = 45});
  final int total;
  final calls = <Map<String, Object?>>[];
  final cancels = <CancelToken?>[];

  @override
  Future<T> get<T>(
    String path, {
    Map<String, Object?>? query,
    CancelToken? cancelToken,
  }) async {
    expect(path, '/api/v1/pages/pg/products');
    calls.add(query ?? {});
    cancels.add(cancelToken);
    final page = query!['page'] as int;
    final size = query['pageSize'] as int;
    final from = (page - 1) * size;
    final n = (total - from).clamp(0, size);
    return {
      'items': [
        for (var i = from; i < from + n; i++)
          {'id': 'p$i', 'name': 'منتج $i', 'price': 1000 + i, 'stock': 1},
      ],
      'page': page,
      'pageSize': size,
      'total': total,
    } as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ArabicFold matches the API', () {
    // Same cases as the API's ArabicTextTests.
    const cases = {
      'أحمر شفاه': 'احمر شفاه',
      'إطار صور': 'اطار صور',
      'آيفون 15': 'ايفون 15',
      'ٱلكتاب': 'الكتاب',
      'مراية دائرية': 'مرايه دايريه',
      'ثلاجة': 'ثلاجه',
      'مستشفى': 'مستشفي',
      'مؤقت': 'موقت',
      'گيمنك': 'كيمنك',
      'ک': 'ك',
      'ی': 'ي',
      'شَاشَةٌ': 'شاشه',
      'مـــرحبا': 'مرحبا',
      'سامسونج ٢٤': 'سامسونج 24',
      '۱۲۳': '123',
      '  iPhone   PRO\t Max ': 'iphone pro max',
      'Air\u00A0Pods': 'air pods',
      '': '',
      '   ': '',
    };
    for (final MapEntry(:key, :value) in cases.entries) {
      test('«$key»', () => expect(ArabicFold.normalize(key), value));
    }

    test('only A-Z is lowered, like the API', () {
      expect(ArabicFold.normalize('ÉCRAN'), 'Écran');
    });

    test('match maps back to the original text', () {
      expect(ArabicFold.match('آيفون 15 برو ماكس', 'ايفون'), (0, 5));
      expect(ArabicFold.match('شَاشَة سمارت', 'شاشه'), (0, 6));
      expect(ArabicFold.match('كفر  ايفون', 'ر اي'), (2, 7));
      expect(ArabicFold.match('iPhone 15', 'PHONE'), (1, 6));
      expect(ArabicFold.match('ايربودز', 'شاشة'), isNull);
      expect(ArabicFold.match('ايربودز', '  ـ '), isNull);
    });

    test('digits folds Arabic-Indic and drops the rest', () {
      expect(ArabicFold.digits('٢٥٠,٠٠٠ د'), '250000');
      expect(ArabicFold.digits('۱2'), '12');
    });
  });

  group('PageProductQuery', () {
    test('is value-equal so it can key providers', () {
      final a = PageProductQuery(q: ' شاشة ', categories: [8, 1, 8]);
      final b = PageProductQuery(q: 'شاشة', categories: [1, 8]);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.categories, [1, 8]);
      expect(a == a.copyWith(inStock: true), isFalse);
    });

    test('sends only what is set', () {
      expect(PageProductQuery().toQuery(page: 1, pageSize: 20), {
        'page': 1,
        'pageSize': 20,
      });
      final q = PageProductQuery(
        q: 'ايفون',
        categories: [3, 1],
        min: 1000,
        max: 5000,
        sort: PageSort.cheapest,
        inStock: true,
      );
      expect(q.toQuery(page: 2, pageSize: 1), {
        'q': 'ايفون',
        'categoryIds': '1,3',
        'minPrice': 1000,
        'maxPrice': 5000,
        'sort': 'price_asc',
        'inStock': true,
        'page': 2,
        'pageSize': 1,
      });
      expect(q.activeCount, 4);
      expect(q.cleared, PageProductQuery(q: 'ايفون'));
    });

    test('blank or tatweel-only text is no search', () {
      expect(PageProductQuery(q: '  ـــ ').searching, isFalse);
      expect(PageProductQuery(q: '  ـــ ').toQuery(page: 1, pageSize: 1), {
        'page': 1,
        'pageSize': 1,
      });
    });

    test('stays inside the API limits', () {
      final q = PageProductQuery(
        q: 'ا' * 80,
        categories: List.generate(30, (i) => i + 1)
          ..add(0)
          ..add(-4),
      );
      expect(q.q.length, PageProductQuery.maxQueryLength);
      expect(q.categories, List.generate(20, (i) => i + 1));
      final t = PageProductQuery(min: 9000, max: 100).tidy;
      expect((t.min, t.max), (100, 9000));
      expect(
        PageProductQuery(min: -5, max: 99999999999999).tidy.max,
        PageProductQuery.maxPrice,
      );
      expect(PageProductQuery(min: -5).tidy.min, 0);
    });
  });

  test('facets skip empty or broken categories', () {
    final f = PageFacets.fromJson({
      'total': 7,
      'inStock': 6,
      'minPrice': 5000,
      'maxPrice': null,
      'categories': [
        {'id': 1, 'slug': 'phones', 'name': 'موبايلات', 'count': 4},
        {'id': 0, 'slug': 'x', 'name': 'x', 'count': 2},
        {'id': 9, 'slug': 'y', 'name': 'y', 'count': 0},
      ],
    });
    expect(f.soldOut, 1);
    expect(f.maxPrice, isNull);
    expect(f.categories.map((c) => c.slug), ['phones']);
    expect(f.categoryName(1), 'موبايلات');
    expect(f.categoryName(9), isNull);
  });

  group('price box', () {
    TextEditingValue type(String s) => const PriceInputFormatter()
        .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: s));

    test('formats and caps', () {
      expect(type('٢٥٠٠٠٠').text, '250,000');
      expect(type('00012a3').text, '123');
      expect(type('9' * 20).text, '999,999,999,999');
      expect(type('').text, '');
      expect(PriceInputFormatter.parse('250,000'), 250000);
      expect(PriceInputFormatter.parse(''), isNull);
    });

    test('labels', () {
      expect(priceRangeLabel(250000, 1000000), '250 ألف – مليون');
      expect(priceRangeLabel(null, 250000), 'لحد 250 ألف');
      expect(priceRangeLabel(2000000, null), 'من 2 مليون');
      expect(priceRangeLabel(12500, 12500), '12,500');
    });
  });

  group('providers', () {
    ProviderContainer box(_Api api) {
      final c = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(api)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('pages through a search with its filters', () async {
      final api = _Api();
      final c = box(api);
      final key = ('pg', PageProductQuery(q: 'منتج', sort: PageSort.priciest));
      final sub = c.listen(pageSearchProvider(key), (_, _) {});
      addTearDown(sub.close);
      await pumpEventQueue();
      expect(c.read(pageSearchProvider(key)).items, hasLength(20));
      await c.read(pageSearchProvider(key).notifier).loadMore();
      await c.read(pageSearchProvider(key).notifier).loadMore();
      final s = c.read(pageSearchProvider(key));
      expect(s.items, hasLength(45));
      expect(s.done, isTrue);
      await c.read(pageSearchProvider(key).notifier).loadMore();
      expect(api.calls, hasLength(3), reason: 'no request after the end');
      expect(api.calls.map((q) => q['page']), [1, 2, 3]);
      expect(api.calls.first['q'], 'منتج');
      expect(api.calls.first['sort'], 'price_desc');
    });

    test('a page that comes back empty ends the list', () async {
      final api = _Api(total: 0);
      final c = box(api);
      final key = ('pg', PageProductQuery());
      final sub = c.listen(pageSearchProvider(key), (_, _) {});
      addTearDown(sub.close);
      await pumpEventQueue();
      final s = c.read(pageSearchProvider(key));
      expect(s.empty, isTrue);
      expect(s.done, isTrue);
    });

    test('a dropped search cancels its request', () async {
      final api = _Api();
      final c = box(api);
      final key = ('pg', PageProductQuery(q: 'a'));
      final sub = c.listen(pageSearchProvider(key), (_, _) {});
      await Future<void>.delayed(Duration.zero);
      expect(api.cancels.single, isNotNull);
      sub.close();
      await pumpEventQueue();
      expect(api.cancels.single!.isCancelled, isTrue);
    });

    test('the apply count asks for one item', () async {
      final api = _Api(total: 12);
      final c = box(api);
      final n = await c.read(
        pageSearchCountProvider(('pg', PageProductQuery(inStock: true))).future,
      );
      expect(n, 12);
      expect(api.calls.single['pageSize'], 1);
      expect(api.calls.single['inStock'], true);
    });

    test('filters stay per page for the session', () {
      final c = box(_Api());
      c.read(pageFilterProvider('pg').notifier).setText('شاشة');
      c
          .read(pageFilterProvider('pg').notifier)
          .apply(PageProductQuery(q: 'ignored', min: 9, max: 1));
      expect(c.read(pageFilterProvider('pg')).q, 'شاشة');
      expect(c.read(pageFilterProvider('pg')).min, 1);
      expect(c.read(pageFilterProvider('other')), PageProductQuery());
      c.read(pageFilterProvider('pg').notifier).clearFilters();
      expect(c.read(pageFilterProvider('pg')), PageProductQuery(q: 'شاشة'));
    });
  });

  test('productCountLabel follows Arabic number agreement', () {
    expect(productCountLabel(0), '0 منتج');
    expect(productCountLabel(1), '1 منتج');
    expect(productCountLabel(2), '2 منتجين');
    expect(productCountLabel(3), '3 منتجات');
    expect(productCountLabel(10), '10 منتجات');
    expect(productCountLabel(11), '11 منتج');
    expect(productCountLabel(17), '17 منتج');
    expect(productCountLabel(103), '103 منتجات');
  });
}
