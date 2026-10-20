import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pages/data/mock_pages_repository.dart';
import '../../pages/domain/pages_repository.dart';
import '../domain/home_models.dart';
import '../domain/home_repository.dart';
import 'mock_home_repository.dart';

/// Swap for the API implementation later. Override in ProviderScope for previews/tests.
final homeRepositoryProvider = Provider<HomeRepository>((ref) => const MockHomeRepository());
final pagesRepositoryProvider = Provider<PagesRepository>((ref) => const MockPagesRepository());

final homeDataProvider = FutureProvider<HomeData>(
  (ref) => ref.watch(homeRepositoryProvider).load(governorate: 'بغداد'),
);

final featuredPagesProvider = FutureProvider.family<FeaturedPages, FeaturedQuery>(
  (ref, q) => ref.watch(pagesRepositoryProvider).featured(q),
);
