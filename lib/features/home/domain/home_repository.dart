import 'home_models.dart';

/// Mirrors GET /v1/home/feed, /home/stats, /home/stories, /requests/active, ads slots.
abstract interface class HomeRepository {
  Future<HomeData> load({required String governorate});

  /// In-stock products of the highest-rated pages, best page first.
  Future<List<HomeProduct>> topRatedProducts({int pages, int perPage});
}
