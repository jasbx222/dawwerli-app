import '../../../core/api/api_client.dart';
import '../../../core/api/catalog.dart';
import '../../more/more_data.dart';
import '../domain/pages_repository.dart';

/// GET /api/v1/pages/featured: paid «إعلان» first, then organic by rating.
class ApiPagesRepository implements PagesRepository {
  const ApiPagesRepository(this.api, this.catalog);
  final ApiClient api;
  final Future<Catalog> catalog;

  @override
  Future<FeaturedPages> featured(FeaturedQuery q) async {
    final cat = await catalog;
    final j = await api.get<Map<String, dynamic>>(
      '/api/v1/pages/featured',
      query: {
        'categoryId': cat.category(q.categoryId)?.id ?? q.categoryId,
        'governorateId': cat.governorateId(q.governorate),
      },
    );
    return FeaturedPages(
      categoryName: j.s('categoryName'),
      governorate: j.s('governorate'),
      pages: [for (final p in j.l('pages')) pageSummaryFromJson(p)],
    );
  }
}
