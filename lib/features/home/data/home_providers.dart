import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../../pages/data/mock_pages_repository.dart';
import '../../pages/domain/pages_repository.dart';
import '../domain/home_models.dart';
import '../domain/home_repository.dart';
import 'mock_home_repository.dart';

/// Swap for the API implementation later. Override in ProviderScope for previews/tests.
final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => const MockHomeRepository(),
);
final pagesRepositoryProvider = Provider<PagesRepository>(
  (ref) => const MockPagesRepository(),
);

final homeDataProvider = FutureProvider<HomeData>(
  (ref) async => ref
      .watch(homeRepositoryProvider)
      .load(governorate: await ref.watch(homeGovernorateProvider.future)),
);

final featuredPagesProvider =
    FutureProvider.family<FeaturedPages, FeaturedQuery>(
      (ref, q) => ref.watch(pagesRepositoryProvider).featured(q),
    );

/// Governorate picked from the home header; null = use the profile's (05).
class SelectedGovernorate extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String gov) => state = gov;
}

final selectedGovernorateProvider =
    NotifierProvider<SelectedGovernorate, String?>(SelectedGovernorate.new);

/// Governorate the home feed/stats are scoped to.
final homeGovernorateProvider = FutureProvider<String>((ref) async {
  final picked = ref.watch(selectedGovernorateProvider);
  return picked ?? await ref.watch(userGovernorateProvider.future);
});
