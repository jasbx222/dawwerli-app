import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/offer.dart';
import 'api_offers_repository.dart';

final offersRepositoryProvider = Provider<OffersRepository>(
  (ref) => ApiOffersRepository(ref.watch(apiClientProvider)),
);

final offersProvider = FutureProvider.autoDispose.family<OffersBoard, String>(
  (ref, id) => ref.watch(offersRepositoryProvider).offers(id),
);

final selectionProvider = FutureProvider.autoDispose.family<Selection?, String>(
  (ref, id) => ref.watch(offersRepositoryProvider).selection(id),
);
