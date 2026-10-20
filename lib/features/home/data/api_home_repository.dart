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
      ad: ad == null
          ? null
          : AdBanner(
              pageName: ad.s('pageName'),
              headline: ad.s('headline'),
              discountPercent: ad.i('discountPercent'),
              pageId: ad.os('pageId') ?? '',
            ),
      featuredPages: [for (final p in j.l('featuredPages')) pageSummaryFromJson(p)],
    );
  }
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
