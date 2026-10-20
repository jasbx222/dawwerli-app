/// Image reference: asset path in mocks, CDN URL from the API later.
typedef ImageRef = String;

class StoryPage {
  const StoryPage({required this.name, required this.image, this.isAd = false});
  final String name;
  final ImageRef image;

  /// Stories are organic; if ever sold, each paid circle must show «إعلان» (spec §16).
  final bool isAd;
}

class LiveRequest {
  const LiveRequest({
    required this.id,
    required this.title,
    required this.image,
    required this.reachedPages,
    required this.governorate,
    required this.offerPrices,
    required this.maxOffers,
    required this.closesAt,
  });
  final String id;
  final String title;
  final ImageRef image;
  final int reachedPages;
  final String governorate;

  /// Offers received so far, cheapest first.
  final List<int> offerPrices;
  final int maxOffers;

  /// Absolute expiry from the server; the card counts down to it.
  final DateTime closesAt;
}

class FeedItem {
  const FeedItem({
    required this.category,
    required this.governorate,
    required this.offers,
    required this.image,
  });
  final String category;
  final String governorate;
  final int offers;
  final ImageRef image;
}

/// Real aggregates from GET /home/stats; each null until it passes the admin threshold.
class HomeStats {
  const HomeStats({
    this.verifiedPages,
    this.governorates,
    this.avgFirstOfferMinutes,
  });
  final int? verifiedPages;
  final int? governorates;
  final int? avgFirstOfferMinutes;

  bool get isEmpty =>
      verifiedPages == null &&
      governorates == null &&
      avgFirstOfferMinutes == null;
}

enum CategoryBadge { none, trending, isNew }

class TrendingCategory {
  const TrendingCategory({
    required this.id,
    required this.name,
    required this.image,
    this.badge = CategoryBadge.none,
  });
  final String id;
  final String name;
  final ImageRef image;
  final CategoryBadge badge;
}

class Deal {
  const Deal({
    required this.category,
    required this.pageName,
    required this.saved,
    required this.image,
  });
  final String category;
  final String pageName;
  final int saved;
  final ImageRef image;
}

class AdBanner {
  const AdBanner({
    required this.pageName,
    required this.headline,
    required this.discountPercent,
    required this.pageId,
  });
  final String pageName;
  final String headline;
  final int discountPercent;
  final String pageId;
}

class PageSummary {
  const PageSummary({
    required this.id,
    required this.name,
    required this.rating,
    required this.deals,
    this.image,
    this.isAd = false,
  });
  final String id;
  final String name;
  final double rating;
  final int deals;
  final ImageRef? image;
  final bool isAd;
}

class HomeData {
  const HomeData({
    required this.firstName,
    required this.area,
    required this.governorate,
    required this.hasUnreadNotifications,
    required this.stories,
    required this.liveRequest,
    required this.ticker,
    required this.stats,
    required this.categories,
    required this.feed,
    required this.deals,
    required this.ad,
    required this.featuredPages,
  });
  final String firstName;
  final String area;
  final String governorate;
  final bool hasUnreadNotifications;
  final List<StoryPage> stories;
  final LiveRequest? liveRequest;
  final List<FeedItem> ticker;
  final HomeStats stats;
  final List<TrendingCategory> categories;
  final List<FeedItem> feed;

  /// Only completed in-app orders; section hidden when empty.
  final List<Deal> deals;
  final AdBanner? ad;
  final List<PageSummary> featuredPages;
}
