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

final homeDataProvider = FutureProvider<HomeData>(
  (ref) => ref
      .watch(homeRepositoryProvider)
      .load(governorate: ref.watch(regionProvider).governorate),
);

final featuredPagesProvider =
    FutureProvider.family<FeaturedPages, FeaturedQuery>(
      (ref, q) => ref.watch(pagesRepositoryProvider).featured(q),
    );
