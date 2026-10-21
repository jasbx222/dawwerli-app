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
    final slotFeatured = await _ads('featuredPage', govId);
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
      featuredPages: _featured(
        [for (final p in j.l('featuredPages')) pageSummaryFromJson(p)],
        slotFeatured,
      ),
    );
  }

  /// Paid placements. A failure here must not blank the rest of home.
  Future<List<Map<String, dynamic>>> _ads(String slot, int? gov) async {
    try {
      return asList(
        await api.get<List<dynamic>>(
          '/api/v1/ads',
          query: {'slot': slot, 'governorateId': ?gov},
        ),
      );
    } on ApiException {
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

/// Paid «صفحة مميزة» first, then organic pages. Same page is not repeated.
List<PageSummary> _featured(
  List<PageSummary> organic,
  List<Map<String, dynamic>> slot,
) {
  final paidIds = <String>{};
  final paid = <PageSummary>[];
  for (final a in slot) {
    final id = a.s('pageId');
    if (id.isEmpty || !paidIds.add(id)) continue;
    final existing = organic.where((p) => p.id == id).firstOrNull;
    paid.add(
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
  return [
    ...paid,
    for (final p in organic)
      if (p.isAd && paidIds.add(p.id)) p,
    for (final p in organic)
      if (!p.isAd && !paidIds.contains(p.id)) p,
  ];
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
