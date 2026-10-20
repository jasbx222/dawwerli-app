import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/post_repository.dart';
import '../domain/request_draft.dart';
import 'mock_post_repository.dart';

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => MockPostRepository(),
);

/// The request being composed; every change is persisted as a draft.
class DraftNotifier extends Notifier<RequestDraft> {
  @override
  RequestDraft build() => const RequestDraft();

  void update(RequestDraft Function(RequestDraft) f) {
    state = f(state);
    ref.read(postRepositoryProvider).saveDraft(state);
  }

  void seed(RequestDraft d) => state = d;
}

final draftProvider = NotifierProvider<DraftNotifier, RequestDraft>(
  DraftNotifier.new,
);

final openCountProvider = FutureProvider<int>(
  (ref) => ref.watch(postRepositoryProvider).openRequestsCount(),
);

final detailSchemaProvider = FutureProvider.family<DetailSchema, String>(
  (ref, cat) => ref.watch(postRepositoryProvider).detailSchema(cat),
);

final suggestedCategoriesProvider = FutureProvider<List<CategoryOption>>(
  (ref) => ref
      .watch(postRepositoryProvider)
      .suggestCategories(ref.read(draftProvider)),
);

/// Example request from the approved designs (07–09), used by `?preview=` routes.
const sampleDraft = RequestDraft(
  photo: 'assets/images/mock/cat_shoes_1.webp',
  description: 'حذاء رياضي أسود، قياس 43، أصلي',
  voiceSeconds: 24,
  category: 'أحذية',
  size: '43',
  color: 'أسود',
  maxPrice: 45000,
  governorate: 'بغداد',
  readyToBuy: true,
  removedContactInfo: true,
);

class SeededDraftNotifier extends DraftNotifier {
  SeededDraftNotifier(this.seedDraft);
  final RequestDraft seedDraft;
  @override
  RequestDraft build() => seedDraft;
}
