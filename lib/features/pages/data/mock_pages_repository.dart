import '../../home/domain/home_models.dart';
import '../domain/pages_repository.dart';

class MockPagesRepository implements PagesRepository {
  const MockPagesRepository();

  @override
  Future<FeaturedPages> featured(FeaturedQuery q) async => const FeaturedPages(
    categoryName: 'أحذية',
    governorate: 'بغداد',
    pages: [
      PageSummary(
        id: 'p1',
        name: 'ستايل بغداد',
        rating: 4.8,
        deals: 120,
        image: 'assets/images/mock/cat_shoes_1.jpg',
        isAd: true,
      ),
      PageSummary(
        id: 'p4',
        name: 'رياضة الكرادة',
        rating: 4.9,
        deals: 210,
        image: 'assets/images/mock/cat_shoes_2.jpg',
        isAd: true,
      ),
      PageSummary(
        id: 'p5',
        name: 'حذاء المنصور',
        rating: 4.6,
        deals: 58,
        image: 'assets/images/mock/cat_shoes_2.jpg',
      ),
    ],
  );
}
