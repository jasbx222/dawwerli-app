import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../discover/data/discover_data.dart';
import 'store_data.dart';

// ───────────────────────── Arabic folding ─────────────────────────

/// The API's search fold (`ArabicText.Normalize`), character for character:
/// alef forms → ا, ة → ه, ى/ئ/ی → ي, ؤ → و, ک/گ → ك, Arabic-Indic digits →
/// 0-9, A-Z → a-z, tashkeel and tatweel dropped, whitespace collapsed.
/// Used to tell an empty search from a real one and to mark the matched
/// part of a name.
abstract final class ArabicFold {
  static const _from =
      '\u0623\u0625\u0622\u0671'
      '\u0629'
      '\u0649\u0626\u06CC'
      '\u0624'
      '\u06A9\u06AF'
      '\u0660\u0661\u0662\u0663\u0664\u0665\u0666\u0667\u0668\u0669'
      '\u06F0\u06F1\u06F2\u06F3\u06F4\u06F5\u06F6\u06F7\u06F8\u06F9'
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
      '\t\n\v\f\r\u00A0';

  static const _to =
      '\u0627\u0627\u0627\u0627'
      '\u0647'
      '\u064A\u064A\u064A'
      '\u0648'
      '\u0643\u0643'
      '0123456789'
      '0123456789'
      'abcdefghijklmnopqrstuvwxyz'
      '      ';

  static const _removed =
      '\u064B\u064C\u064D\u064E\u064F\u0650\u0651\u0652\u0653\u0654\u0655'
      '\u0656\u0657\u0658\u0659\u065A\u065B\u065C\u065D\u065E\u065F'
      '\u0670\u0640';

  static String normalize(String text) => _fold(text).$1;

  /// Folded text and, per folded code unit, its index in [text].
  static (String, List<int>) _fold(String text) {
    final out = StringBuffer();
    final at = <int>[];
    var space = true; // drops leading spaces and collapses runs
    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (_removed.contains(c)) continue;
      final k = _from.indexOf(c);
      final m = k >= 0 ? _to[k] : c;
      if (m == ' ') {
        if (space) continue;
        space = true;
      } else {
        space = false;
      }
      out.write(m);
      at.add(i);
    }
    var s = out.toString();
    if (s.endsWith(' ')) {
      s = s.substring(0, s.length - 1);
      at.removeLast();
    }
    return (s, at);
  }

  /// Where the folded [query] first occurs in [text], as a [start, end)
  /// range of [text]; null when it is not there or the query is empty.
  static (int, int)? match(String text, String query) {
    final term = normalize(query);
    if (term.isEmpty) return null;
    final (folded, at) = _fold(text);
    final i = folded.indexOf(term);
    if (i < 0) return null;
    return (at[i], at[i + term.length - 1] + 1);
  }

  /// Latin digits from any digits the user typed (٠-٩, ۰-۹); others dropped.
  static String digits(String s) {
    final b = StringBuffer();
    for (final c in s.split('')) {
      final k = _from.indexOf(c);
      final m = k >= 0 ? _to[k] : c;
      if (m.codeUnitAt(0) >= 0x30 && m.codeUnitAt(0) <= 0x39) b.write(m);
    }
    return b.toString();
  }
}

// ───────────────────────── Query ─────────────────────────

enum PageSort {
  newest('newest', 'الأحدث'),
  cheapest('price_asc', 'الأرخص'),
  priciest('price_desc', 'الأغلى'),
  bestSelling('best_selling', 'الأكثر مبيعاً'),
  topRated('top_rated', 'الأعلى تقييماً');

  const PageSort(this.api, this.label);
  final String api;
  final String label;
}

/// What a customer searches a page for: text plus the drawer filters.
/// Value-equal, so it can key providers.
@immutable
class PageProductQuery {
  PageProductQuery({
    String q = '',
    Iterable<int> categories = const [],
    this.min,
    this.max,
    this.sort = PageSort.newest,
    this.inStock = false,
  }) : q = q.trim().length > maxQueryLength
           ? q.trim().substring(0, maxQueryLength)
           : q.trim(),
       categories = List.unmodifiable(
         (categories.where((c) => c > 0).toSet().toList()..sort()).take(
           maxCategories,
         ),
       );

  /// The API's limits (longer text or more categories are a 400).
  static const maxQueryLength = 60;
  static const maxCategories = 20;
  static const maxPrice = 999999999999;

  final String q;
  final List<int> categories;
  final int? min;
  final int? max;
  final PageSort sort;
  final bool inStock;

  /// Folded text is what the API matches on; spaces or tatweel alone are
  /// no search at all.
  bool get searching => ArabicFold.normalize(q).isNotEmpty;

  /// Drawer filters in use (the badge and the chips; text not counted).
  int get activeCount =>
      (categories.isNotEmpty ? 1 : 0) +
      (min != null || max != null ? 1 : 0) +
      (sort != PageSort.newest ? 1 : 0) +
      (inStock ? 1 : 0);

  bool get narrowed => searching || activeCount > 0;

  PageProductQuery copyWith({
    String? q,
    Iterable<int>? categories,
    int? Function()? min,
    int? Function()? max,
    PageSort? sort,
    bool? inStock,
  }) => PageProductQuery(
    q: q ?? this.q,
    categories: categories ?? this.categories,
    min: min != null ? min() : this.min,
    max: max != null ? max() : this.max,
    sort: sort ?? this.sort,
    inStock: inStock ?? this.inStock,
  );

  /// Same text, no drawer filters.
  PageProductQuery get cleared => PageProductQuery(q: q);

  /// Price bounds in range and in order (swapped when typed backwards).
  PageProductQuery get tidy {
    int? c(int? v) => v?.clamp(0, maxPrice);
    var (a, b) = (c(min), c(max));
    if (a != null && b != null && a > b) (a, b) = (b, a);
    return copyWith(min: () => a, max: () => b);
  }

  Map<String, Object?> toQuery({required int page, required int pageSize}) => {
    if (searching) 'q': q,
    if (categories.isNotEmpty) 'categoryIds': categories.join(','),
    if (min != null) 'minPrice': min,
    if (max != null) 'maxPrice': max,
    if (sort != PageSort.newest) 'sort': sort.api,
    if (inStock) 'inStock': true,
    'page': page,
    'pageSize': pageSize,
  };

  @override
  bool operator ==(Object other) =>
      other is PageProductQuery &&
      other.q == q &&
      listEquals(other.categories, categories) &&
      other.min == min &&
      other.max == max &&
      other.sort == sort &&
      other.inStock == inStock;

  @override
  int get hashCode =>
      Object.hash(q, Object.hashAll(categories), min, max, sort, inStock);

  @override
  String toString() =>
      'PageProductQuery($q, $categories, $min, $max, ${sort.api}, $inStock)';
}

// ───────────────────────── Facets ─────────────────────────

class PageCategoryFacet {
  const PageCategoryFacet({
    required this.id,
    required this.slug,
    required this.name,
    required this.count,
  });
  final int id;
  final String slug;
  final String name;
  final int count;

  factory PageCategoryFacet.fromJson(Map<String, dynamic> j) =>
      PageCategoryFacet(
        id: j.i('id'),
        slug: j.s('slug'),
        name: j.s('name'),
        count: j.i('count'),
      );
}

/// GET /pages/{id}/product-facets: what the drawer can offer.
class PageFacets {
  const PageFacets({
    required this.total,
    required this.inStock,
    this.minPrice,
    this.maxPrice,
    this.categories = const [],
  });
  final int total;
  final int inStock;
  final int? minPrice;
  final int? maxPrice;
  final List<PageCategoryFacet> categories;

  int get soldOut => total - inStock;

  String? categoryName(int id) {
    for (final c in categories) {
      if (c.id == id) return c.name;
    }
    return null;
  }

  factory PageFacets.fromJson(Map<String, dynamic> j) => PageFacets(
    total: j.i('total'),
    inStock: j.i('inStock'),
    minPrice: j.oi('minPrice'),
    maxPrice: j.oi('maxPrice'),
    categories: [
      for (final c in j.l('categories'))
        if (c.i('id') > 0 && c.i('count') > 0) PageCategoryFacet.fromJson(c),
    ],
  );
}

// ───────────────────────── Providers ─────────────────────────

/// The search a customer left on each page; kept for the session so going
/// into a product and back (or to another page and back) keeps it.
final pageFilterProvider =
    NotifierProvider.family<PageFilterNotifier, PageProductQuery, String>(
      PageFilterNotifier.new,
    );

class PageFilterNotifier extends Notifier<PageProductQuery> {
  PageFilterNotifier(this.pageId);
  final String pageId;

  @override
  PageProductQuery build() => PageProductQuery();

  void setText(String q) => state = state.copyWith(q: q);

  /// The drawer's choice; the text stays what the box says.
  void apply(PageProductQuery filters) =>
      state = filters.tidy.copyWith(q: state.q);

  void set(PageProductQuery q) => state = q.tidy;

  void clearFilters() => state = state.cleared;
}

final pageFacetsProvider = FutureProvider.autoDispose
    .family<PageFacets, String>((ref, pageId) async {
      final raw = await ref
          .watch(apiClientProvider)
          .get<Map<String, dynamic>>('/api/v1/pages/$pageId/product-facets');
      return PageFacets.fromJson(raw);
    });

typedef PageSearchKey = (String pageId, PageProductQuery query);

/// One page's products for one search, page by page. Each search is its
/// own provider, so a new search starts clean and the old one is disposed
/// with its request cancelled.
final pageSearchProvider = NotifierProvider.autoDispose
    .family<PageSearchNotifier, PagedState<StoreProduct>, PageSearchKey>(
      PageSearchNotifier.new,
    );

class PageSearchNotifier extends PagedNotifier<StoreProduct> {
  PageSearchNotifier(this.key);
  final PageSearchKey key;
  CancelToken? _cancel;

  @override
  PagedState<StoreProduct> build() {
    ref.onDispose(() => _cancel?.cancel());
    return super.build();
  }

  @override
  Future<Paged<StoreProduct>> fetch(int page) async {
    final cancel = _cancel = CancelToken();
    final r = pagedFromJson(
      await ref
          .read(apiClientProvider)
          .get<Object?>(
            '/api/v1/pages/${key.$1}/products',
            query: key.$2.toQuery(page: page, pageSize: PagedNotifier.pageSize),
            cancelToken: cancel,
          ),
      StoreProduct.fromJson,
    );
    // Products removed while scrolling: stop instead of asking forever.
    if (r.items.isEmpty) return Paged(r.items, state.items.length);
    return r;
  }
}

/// How many products a search would show («طبّق · N»): `pageSize=1`.
final pageSearchCountProvider = FutureProvider.autoDispose
    .family<int, PageSearchKey>((ref, key) async {
      final cancel = CancelToken();
      ref.onDispose(cancel.cancel);
      final raw = await ref
          .watch(apiClientProvider)
          .get<Object?>(
            '/api/v1/pages/${key.$1}/products',
            query: key.$2.toQuery(page: 1, pageSize: 1),
            cancelToken: cancel,
          );
      return pagedFromJson(raw, (j) => j).total;
    });

/// "N منتج" with Arabic number agreement: 1 → منتج, 2 → منتجين,
/// 3–10 → منتجات, otherwise (0, 11+) → منتج.
String productCountLabel(int n) {
  final r = n % 100;
  final word = n == 2
      ? 'منتجين'
      : (r >= 3 && r <= 10)
      ? 'منتجات'
      : 'منتج';
  return '$n $word';
}
