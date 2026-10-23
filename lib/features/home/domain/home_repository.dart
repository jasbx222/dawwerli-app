import 'home_models.dart';

/// Mirrors GET /v1/home/feed, /home/stats, /home/stories, /requests/active, ads slots.
abstract interface class HomeRepository {
  /// [governorate] null → the server uses the signed-in profile's governorate
  /// (or its default for guests).
  Future<HomeData> load({String? governorate});

  /// In-stock products of the highest-rated pages, best page first.
  Future<List<HomeProduct>> topRatedProducts({int pages, int perPage});
}
