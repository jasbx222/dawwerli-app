import '../../home/domain/home_models.dart';

class FeaturedQuery {
  const FeaturedQuery({required this.categoryId, required this.governorate});
  final String categoryId;
  final String governorate;

  @override
  bool operator ==(Object other) =>
      other is FeaturedQuery &&
      other.categoryId == categoryId &&
      other.governorate == governorate;

  @override
  int get hashCode => Object.hash(categoryId, governorate);
}

class FeaturedPages {
  const FeaturedPages({
    required this.categoryName,
    required this.governorate,
    required this.pages,
  });
  final String categoryName;
  final String governorate;

  /// Paid («إعلان») first, then organic by rating (rating ≥ 4, no confirmed complaints).
  final List<PageSummary> pages;
}

abstract interface class PagesRepository {
  Future<FeaturedPages> featured(FeaturedQuery q);
}
