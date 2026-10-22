/// Page (seller) side models. All limits come from [SellerConfig] (GET /api/v1/config).
class SellerConfig {
  const SellerConfig({
    this.selectionFee = 1000,
    this.freeSelections = 10,
    this.maxOffers = 5,
    this.earlyWindow = const Duration(minutes: 2),
    this.maxEarlySlots = 2,
    this.replyWindow = const Duration(hours: 1),
    this.ghostAfter = const Duration(hours: 24),
    this.earlyAccessMonthly = 15000,
    this.bannerDaily = 5000,
    this.featuredWeekly = 20000,
    this.sponsoredOffer = 1500,
    this.minAdRating = 4.0,
    this.appealHours = 48,
    this.trustedDeals = 100,
    this.minTopUp = 5000,
    this.topupMethods = const ['ZainCash', 'FIB', 'Qi'],
  });

  /// Values from GET /api/v1/config (admin-editable business rules).
  factory SellerConfig.fromJson(Map<String, dynamic> j) {
    int i(String k) => (j[k] as num).toInt();
    return SellerConfig(
      selectionFee: i('selectionFee'),
      freeSelections: i('freeSelections'),
      maxOffers: i('maxOffers'),
      earlyWindow: Duration(seconds: i('earlyWindowSec')),
      maxEarlySlots: i('maxEarlySlots'),
      replyWindow: Duration(minutes: i('replyWindowMin')),
      ghostAfter: Duration(hours: i('ghostAfterHours')),
      earlyAccessMonthly: i('earlyAccessMonthly'),
      bannerDaily: i('bannerDaily'),
      featuredWeekly: i('featuredWeekly'),
      sponsoredOffer: i('sponsoredOffer'),
      minAdRating: (j['minAdRating'] as num).toDouble(),
      appealHours: i('disputeDecisionHours'),
      trustedDeals: i('trustedDeals'),
      minTopUp: i('minTopUp'),
      topupMethods: (j['topUpMethods'] as List).cast<String>(),
    );
  }
  final int selectionFee;
  final int freeSelections;
  final int maxOffers;
  final Duration earlyWindow;
  final int maxEarlySlots;
  final Duration replyWindow;
  final Duration ghostAfter;
  final int earlyAccessMonthly;
  final int bannerDaily;
  final int featuredWeekly;
  final int sponsoredOffer;
  final double minAdRating;
  final int appealHours;
  final int trustedDeals;
  final int minTopUp;
  final List<String> topupMethods;
}

enum VerifyStatus { none, pending, verified, rejected }

class SellerRequest {
  const SellerRequest({
    required this.id,
    required this.title,
    required this.image,
    required this.governorate,
    required this.condition,
    required this.maxPrice,
    required this.postedAt,
    required this.offers,
    this.earlyUntil,
    this.earlyTaken = 0,
    this.offeredByMe = false,
    this.cancelled = false,
    this.category = '',
    this.categoryId = 0,
  });
  final String id;
  final String title;
  final String image;
  final String governorate;
  final String condition;
  final int maxPrice;
  final DateTime postedAt;
  final int offers;

  /// Set while this page (an early-access subscriber) sees it before others.
  final DateTime? earlyUntil;

  /// Offers already taken by early-access pages inside the window.
  final int earlyTaken;
  final bool offeredByMe;
  final bool cancelled;
  final String category;
  final int categoryId;

  bool isEarly(DateTime now) => earlyUntil != null && now.isBefore(earlyUntil!);
  bool locked(int max) => cancelled || offers >= max;

  SellerRequest copyWith({int? offers, bool? offeredByMe, int? earlyTaken}) =>
      SellerRequest(
        id: id,
        title: title,
        image: image,
        governorate: governorate,
        condition: condition,
        maxPrice: maxPrice,
        postedAt: postedAt,
        offers: offers ?? this.offers,
        earlyUntil: earlyUntil,
        earlyTaken: earlyTaken ?? this.earlyTaken,
        offeredByMe: offeredByMe ?? this.offeredByMe,
        cancelled: cancelled,
        category: category,
        categoryId: categoryId,
      );
}

/// Home feed filters (GET /pages/me/feed). Null = no filter.
enum FeedSince { all, today, week, month }

enum FeedSort { newest, oldest, priceAsc, priceDesc }

class FeedFilter {
  const FeedFilter({
    this.categoryId,
    this.since = FeedSince.all,
    this.sort = FeedSort.newest,
    this.minPrice,
    this.maxPrice,
  });
  final int? categoryId;
  final FeedSince since;
  final FeedSort sort;
  final int? minPrice;
  final int? maxPrice;

  /// Filters other than the default sort (the badge on «فلترة»).
  int get active =>
      (categoryId != null ? 1 : 0) +
      (since != FeedSince.all ? 1 : 0) +
      (sort != FeedSort.newest ? 1 : 0) +
      (minPrice != null || maxPrice != null ? 1 : 0);

  FeedFilter copyWith({
    int? Function()? categoryId,
    FeedSince? since,
    FeedSort? sort,
    int? Function()? minPrice,
    int? Function()? maxPrice,
  }) => FeedFilter(
    categoryId: categoryId == null ? this.categoryId : categoryId(),
    since: since ?? this.since,
    sort: sort ?? this.sort,
    minPrice: minPrice == null ? this.minPrice : minPrice(),
    maxPrice: maxPrice == null ? this.maxPrice : maxPrice(),
  );

  Map<String, Object?> query(int page, int pageSize) => {
    'categoryId': ?categoryId,
    if (since != FeedSince.all) 'since': since.name,
    'sort': sort.name,
    'minPrice': ?minPrice,
    'maxPrice': ?maxPrice,
    'page': page,
    'pageSize': pageSize,
  };

  @override
  bool operator ==(Object other) =>
      other is FeedFilter &&
      other.categoryId == categoryId &&
      other.since == since &&
      other.sort == sort &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice;

  @override
  int get hashCode => Object.hash(categoryId, since, sort, minPrice, maxPrice);
}

class FeedPage {
  const FeedPage(this.items, this.total);
  final List<SellerRequest> items;
  final int total;
}

enum OfferState { chosen, waiting, notChosen, closed, withdrawn }

class SellerOffer {
  const SellerOffer({
    required this.id,
    required this.requestId,
    required this.title,
    required this.image,
    required this.price,
    required this.state,
    this.orderId,
    this.orderNo,
    this.chosenAt,
    this.contacted = false,
    this.ghostReported = false,
    this.selectionNo,
    this.governorate = 'بغداد',
    this.customerPhone,
    this.sentAt,
    this.category = '',
    this.requestMaxPrice,
  });

  final DateTime? sentAt;
  final String category;
  final int? requestMaxPrice;

  /// Only while the order is Selected/InProgress; null afterwards (§16).
  final String? customerPhone;
  final String id;
  final String requestId;
  final String title;
  final String image;
  final int price;
  final OfferState state;
  final String? orderId;
  final String? orderNo;
  final DateTime? chosenAt;
  final bool contacted;
  final bool ghostReported;
  final int? selectionNo;
  final String governorate;

  SellerOffer copyWith({
    OfferState? state,
    bool? contacted,
    bool? ghostReported,
  }) => SellerOffer(
    id: id,
    requestId: requestId,
    title: title,
    image: image,
    price: price,
    state: state ?? this.state,
    orderId: orderId,
    orderNo: orderNo,
    chosenAt: chosenAt,
    contacted: contacted ?? this.contacted,
    ghostReported: ghostReported ?? this.ghostReported,
    selectionNo: selectionNo,
    governorate: governorate,
    customerPhone: customerPhone,
    sentAt: sentAt,
    category: category,
    requestMaxPrice: requestMaxPrice,
  );
}

enum LedgerKind { debit, free, held, credit }

class LedgerEntry {
  const LedgerEntry(this.title, this.sub, this.amount, this.kind);
  final String title;
  final String sub;
  final int amount;
  final LedgerKind kind;
}

enum TopupStatus { pending, approved, rejected }

class Topup {
  const Topup(this.ref, this.method, this.amount, this.at, this.status);
  final String ref;
  final String method;
  final int amount;
  final DateTime at;
  final TopupStatus status;
}

enum AdSlot { homeBanner, featuredPage, sponsoredOffer }

enum AdStatus {
  pending,
  rejected,
  pausedBalance,
  pausedSuspended,
  active,
  ended,
}

class AdCampaign {
  const AdCampaign({
    required this.id,
    required this.slot,
    required this.title,
    required this.place,
    required this.image,
    required this.status,
    this.note,
    this.impressions = 0,
    this.clicks = 0,
    this.selections = 0,
  });
  final String id;
  final AdSlot slot;
  final String title;
  final String place;
  final String image;
  final AdStatus status;
  final String? note;
  final int impressions;
  final int clicks;
  final int selections;
}

enum MarkKind { mark, review }

class PageMark {
  const PageMark(this.id, this.title, this.sub, this.kind, {this.orderNo});
  final String id;
  final String title;
  final String sub;
  final MarkKind kind;
  final String? orderNo;
}

class PageSettings {
  const PageSettings({
    this.receiving = true,
    this.sound = true,
    this.categories = const {},
    this.governorates = const {},
    this.from = 10,
    this.to = 23,
    this.days = const {0, 1, 2, 3, 4, 5},
  });
  final bool receiving;
  final bool sound;
  final Set<String> categories;
  final Set<String> governorates;

  /// Working hours (24h clock, Asia/Baghdad).
  final int from;
  final int to;

  /// 0 = السبت … 6 = الجمعة.
  final Set<int> days;

  PageSettings copyWith({
    bool? receiving,
    bool? sound,
    Set<String>? categories,
    Set<String>? governorates,
    int? from,
    int? to,
    Set<int>? days,
  }) => PageSettings(
    receiving: receiving ?? this.receiving,
    sound: sound ?? this.sound,
    categories: categories ?? this.categories,
    governorates: governorates ?? this.governorates,
    from: from ?? this.from,
    to: to ?? this.to,
    days: days ?? this.days,
  );
}

class ReceivedRating {
  const ReceivedRating({
    required this.orderNo,
    required this.stars,
    required this.tags,
    required this.comment,
    required this.governorate,
  });
  final String orderNo;
  final int stars;
  final List<String> tags;
  final String comment;
  final String governorate;
}

class SellerNotice {
  const SellerNotice(this.title, this.body, this.route, this.ago);
  final String title;
  final String body;
  final String route;
  final String ago;
}
