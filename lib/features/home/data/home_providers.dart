import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/catalog.dart';
import '../../more/more_data.dart';
import '../../pages/data/api_pages_repository.dart';
import '../../pages/domain/pages_repository.dart';
import '../domain/home_models.dart';
import '../domain/home_repository.dart';
import 'api_home_repository.dart';

/// Override in ProviderScope for previews/tests.
final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => ApiHomeRepository(
    ref.watch(apiClientProvider),
    ref.watch(catalogProvider.future),
  ),
);
final pagesRepositoryProvider = Provider<PagesRepository>(
  (ref) => ApiPagesRepository(
    ref.watch(apiClientProvider),
    ref.watch(catalogProvider.future),
  ),
);

final homeDataProvider = FutureProvider<HomeData>((ref) {
  final region = ref.watch(regionProvider);
  return ref
      .watch(homeRepositoryProvider)
      .load(governorate: region.explicit ? region.governorate : null);
});

final featuredPagesProvider =
    FutureProvider.family<FeaturedPages, FeaturedQuery>(
      (ref, q) => ref.watch(pagesRepositoryProvider).featured(q),
    );

/// «منتجات أعلى الصفحات تقييماً» → «الكل». Falls back to the home strip when
/// the server has no top-rated endpoint yet.
final topRatedProductsProvider = FutureProvider.autoDispose<List<HomeProduct>>((
  ref,
) async {
  try {
    return await ref
        .watch(homeRepositoryProvider)
        .topRatedProducts(pages: 12, perPage: 6);
  } on Object {
    return (await ref.watch(homeDataProvider.future)).topProducts;
  }
});
