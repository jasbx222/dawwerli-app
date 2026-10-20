import '../domain/home_models.dart';
import '../domain/home_repository.dart';

const _img = 'assets/images/mock';

/// Mock home. [withData] = the design's example data (06); false = cold start (06b: stats hidden, no deals).
class MockHomeRepository implements HomeRepository {
  const MockHomeRepository({this.withData = false});
  final bool withData;

  @override
  Future<HomeData> load({required String governorate}) async {
    return HomeData(
      firstName: 'أبو علي',
      area: 'الكرادة',
      governorate: governorate,
      hasUnreadNotifications: true,
      stories: const [
        StoryPage(name: 'ستايل بغداد', image: '$_img/shoe.jpg'),
        StoryPage(name: 'موبايل زون', image: '$_img/phone.jpg'),
        StoryPage(name: 'عطور الشرق', image: '$_img/perfume.jpg'),
        StoryPage(name: 'بوتيك ريم', image: '$_img/dress.jpg'),
        StoryPage(name: 'ساعات النخبة', image: '$_img/watch.jpg'),
        StoryPage(name: 'بيتي', image: '$_img/lamp.jpg'),
      ],
      liveRequest: const LiveRequest(
        id: 'r1',
        title: 'حذاء رياضي أسود · 43',
        image: '$_img/shoe.jpg',
        reachedPages: 14,
        governorate: 'بغداد',
        offerPrices: [35000, 39000, 42000],
        maxOffers: 5,
        closesIn: Duration(hours: 23, minutes: 41),
      ),
      ticker: const [
        FeedItem(category: 'أحذية', governorate: 'بغداد', offers: 3, image: ''),
        FeedItem(
          category: 'موبايلات',
          governorate: 'البصرة',
          offers: 5,
          image: '',
        ),
        FeedItem(category: 'عطور', governorate: 'أربيل', offers: 2, image: ''),
        FeedItem(category: 'ملابس', governorate: 'بابل', offers: 4, image: ''),
      ],
      stats: withData
          ? HomeStats(
              verifiedPages: _pagesByGov[governorate] ?? 120,
              governorates: 18,
              avgFirstOfferMinutes: 7,
            )
          : const HomeStats(),
      categories: const [
        TrendingCategory(
          id: 'phones',
          name: 'موبايلات',
          image: '$_img/phone.jpg',
          badge: CategoryBadge.trending,
        ),
        TrendingCategory(
          id: 'perfumes',
          name: 'عطور',
          image: '$_img/perfume.jpg',
        ),
        TrendingCategory(
          id: 'eid',
          name: 'هدوم العيد',
          image: '$_img/shirt.jpg',
        ),
        TrendingCategory(
          id: 'care',
          name: 'عناية',
          image: '$_img/cosmetics.jpg',
          badge: CategoryBadge.isNew,
        ),
        TrendingCategory(
          id: 'home',
          name: 'أغراض البيت',
          image: '$_img/lamp.jpg',
        ),
      ],
      // Local-first: requests from the chosen governorate rank first.
      feed: _localFirst(governorate, const [
        FeedItem(
          category: 'موبايلات',
          governorate: 'بغداد',
          offers: 4,
          image: '$_img/phone.jpg',
        ),
        FeedItem(
          category: 'ملابس',
          governorate: 'البصرة',
          offers: 2,
          image: '$_img/jacket.jpg',
        ),
        FeedItem(
          category: 'عطور',
          governorate: 'أربيل',
          offers: 5,
          image: '$_img/perfume.jpg',
        ),
      ]),
      deals: withData
          ? const [
              Deal(
                category: 'ساعات',
                pageName: 'ستايل بغداد',
                saved: 18000,
                image: '$_img/watch.jpg',
              ),
              Deal(
                category: 'ملابس',
                pageName: 'بوتيك ريم',
                saved: 25000,
                image: '$_img/dress.jpg',
              ),
              Deal(
                category: 'إلكترونيات',
                pageName: 'موبايل زون',
                saved: 12000,
                image: '$_img/headphones.jpg',
              ),
            ]
          : const [],
      ad: const AdBanner(
        pageName: 'ستايل بغداد',
        headline: 'كل الأحذية الرياضية',
        discountPercent: 20,
        pageId: 'p1',
      ),
      featuredPages: const [
        PageSummary(
          id: 'p1',
          name: 'ستايل بغداد',
          rating: 4.8,
          deals: 120,
          isAd: true,
        ),
        PageSummary(
          id: 'p2',
          name: 'موبايل زون',
          rating: 4.7,
          deals: 86,
          isAd: true,
        ),
        PageSummary(id: 'p3', name: 'بيتي', rating: 4.9, deals: 64, isAd: true),
      ],
    );
  }

  /// Mock verified-page counts per governorate (real: GET /v1/home/stats?gov=).
  static const _pagesByGov = {
    'بغداد': 1240,
    'البصرة': 410,
    'أربيل': 380,
    'نينوى': 260,
    'النجف': 210,
    'كربلاء': 190,
    'بابل': 150,
  };

  static List<FeedItem> _localFirst(String gov, List<FeedItem> items) => [
    ...items.where((f) => f.governorate == gov),
    ...items.where((f) => f.governorate != gov),
  ];
}
