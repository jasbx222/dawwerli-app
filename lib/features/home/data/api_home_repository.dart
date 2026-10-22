import '../../../core/api/api_client.dart';
import '../../../core/api/catalog.dart';
import '../../more/more_data.dart';
import '../domain/home_models.dart';
import '../domain/home_repository.dart';

/// GET /api/v1/home: stories, live request, ticker, stats, categories, feed, deals, ad, featured pages.
class ApiHomeRepository implements HomeRepository {
  const ApiHomeRepository(this.api, this.catalog);
  final ApiClient api;
  final Future<Catalog> catalog;

  static const _badges = {
    'trending': CategoryBadge.trending,
    'new': CategoryBadge.isNew,
    'isNew': CategoryBadge.isNew,
  };

  @override
  Future<HomeData> load({required String governorate}) async {
    final gov = (await catalog).governorateId(governorate);
    final j = await api.get<Map<String, dynamic>>(
      '/api/v1/home',
      query: {'governorateId': ?gov},
    );
    final live = j.om('liveRequest');
    final ad = j.om('ad');
    final stats = j.m('stats');
    final govId = gov;
    final slotBanners = await _ads('homeBanner', govId);
    final slotSponsored = await _ads('sponsoredOffer', govId);
    final catIds = <int>{
      for (final c in j.l('categories'))
        if (c.i('id') != 0) c.i('id'),
    };
    final featuredBuckets = await Future.wait([
      _ads('featuredPage', govId),
      for (final id in catIds) _ads('featuredPage', govId, categoryId: id),
    ]);
    final slotFeatured = [for (final bucket in featuredBuckets) ...bucket];
    final organicFeatured = [
      for (final p in j.l('featuredPages')) pageSummaryFromJson(p),
    ];
    return HomeData(
      firstName: j.os('firstName') ?? '',
      area: j.os('area') ?? '',
      governorate: j.s('governorate'),
      hasUnreadNotifications: j.b('hasUnreadNotifications'),
      stories: [
        for (final s in j.l('stories'))
          StoryPage(
            pageId: s.s('pageId'),
            name: s.s('name'),
            image: s.os('image') ?? '',
            isAd: s.b('isAd'),
          ),
      ],
      liveRequest: live == null ? null : liveRequestFromJson(live),
      ticker: [for (final f in j.l('ticker')) feedItemFromJson(f)],
      stats: HomeStats(
        verifiedPages: stats.oi('verifiedPages'),
        governorates: stats.oi('governorates'),
        avgFirstOfferMinutes: stats.oi('avgFirstOfferMinutes'),
      ),
      categories: [
        for (final c in j.l('categories'))
          TrendingCategory(
            id: '${c.i('id')}',
            name: c.s('name'),
            image: c.os('image') ?? '',
            badge: _badges[c.s('badge')] ?? CategoryBadge.none,
          ),
      ],
      feed: [for (final f in j.l('feed')) feedItemFromJson(f)],
      deals: [
        for (final d in j.l('deals'))
          Deal(
            category: d.s('category'),
            pageName: d.s('pageName'),
            saved: d.i('saved'),
            image: d.os('image') ?? '',
          ),
      ],
      banners: _banners(ad, slotBanners),
      sponsored: _sponsoredPages(slotSponsored, organicFeatured),
      featuredPages: featuredWithPaid(organicFeatured, slotFeatured),
      topProducts: await _topProducts(organicFeatured),
    );
  }

  /// Paid placements. A failure here must not blank the rest of home.
  Future<List<Map<String, dynamic>>> _ads(
    String slot,
    int? gov, {
    int? categoryId,
  }) async {
    try {
      return asList(
        await api.get<List<dynamic>>(
          '/api/v1/ads',
          query: {
            'slot': slot,
            'governorateId': ?gov,
            'categoryId': ?categoryId,
          },
        ),
      );
    } on ApiException {
      return const [];
    }
  }

  /// Products of the highest-rated pages. A failure must not blank home.
  Future<List<HomeProduct>> _topProducts(List<PageSummary> pages) async {
    final ranked = [...pages]..sort((a, b) {
      final byRating = b.rating.compareTo(a.rating);
      return byRating != 0 ? byRating : b.deals.compareTo(a.deals);
    });
    final rated = ranked.where((p) => p.rating > 0).take(4).toList();
    final picked = rated.isEmpty ? ranked.take(4).toList() : rated;
    final lists = await Future.wait(picked.map(_productsOf));
    return [for (final list in lists) ...list].take(8).toList();
  }

  Future<List<HomeProduct>> _productsOf(PageSummary page) async {
    try {
      final list = asList(
        await api.get<List<dynamic>>('/api/v1/pages/${page.id}/products'),
      );
      final out = <HomeProduct>[];
      for (final p in list) {
        if (p.containsKey('available') && p['available'] == false) continue;
        final name = p.s('name');
        final id = p.s('id');
        if (name.isEmpty || id.isEmpty) continue;
        final urls = ((p['imageUrls'] as List?) ?? const [])
            .whereType<String>()
            .where((u) => u.isNotEmpty)
            .toList();
        out.add(
          HomeProduct(
            pageId: page.id,
            pageName: page.name,
            id: id,
            name: name,
            price: p.i('price'),
            image: urls.isNotEmpty ? urls.first : (p.os('image') ?? ''),
          ),
        );
        if (out.length == 2) break;
      }
      return out;
    } on Object {
      return const [];
    }
  }
}

AdBanner _bannerFrom(Map<String, dynamic> a) => AdBanner(
  pageName: a.s('pageName'),
  headline: a.s('headline').isNotEmpty ? a.s('headline') : a.s('title'),
  discountPercent: a.i('discountPercent'),
  pageId: a.s('pageId').isNotEmpty ? a.s('pageId') : (a.os('pageId') ?? ''),
  image: a.os('image'),
);

List<AdBanner> _banners(
  Map<String, dynamic>? homeAd,
  List<Map<String, dynamic>> slot,
) {
  final out = <AdBanner>[
    for (final a in slot)
      if (a.s('pageId').isNotEmpty || a.s('pageName').isNotEmpty) _bannerFrom(a),
  ];
  if (out.isEmpty && homeAd != null) out.add(_bannerFrom(homeAd));
  return out;
}

/// Paid «عرض مُموّل», one card per page.
List<PageSummary> _sponsoredPages(
  List<Map<String, dynamic>> slot,
  List<PageSummary> known,
) {
  final ids = <String>{};
  final out = <PageSummary>[];
  for (final a in slot) {
    final id = a.s('pageId');
    if (id.isEmpty || !ids.add(id)) continue;
    final existing = known.where((p) => p.id == id).firstOrNull;
    out.add(
      PageSummary(
        id: id,
        name: existing?.name.isNotEmpty == true ? existing!.name : a.s('pageName'),
        rating: existing?.rating ?? 0,
        deals: existing?.deals ?? 0,
        image: existing?.image ?? a.os('image'),
        isAd: true,
      ),
    );
  }
  return out;
}

LiveRequest liveRequestFromJson(Map<String, dynamic> r) => LiveRequest(
  id: r.s('id'),
  title: r.s('title'),
  image: r.os('image') ?? '',
  reachedPages: r.i('reachedPages'),
  governorate: r.s('governorate'),
  offerPrices: [for (final p in r.list<num>('offerPrices')) p.toInt()],
  maxOffers: r.i('maxOffers'),
  closesAt: r.t('expiresAt'),
);
