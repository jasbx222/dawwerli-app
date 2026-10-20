import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mock/mock_backend.dart';
import '../../../core/storage/prefs.dart';

import '../domain/post_repository.dart';
import '../domain/request_draft.dart';
import 'mock_post_repository.dart';

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => MockPostRepository(backend: ref.watch(mockBackendProvider)),
);

/// The request being composed; every change is saved on the device
/// (survives an app restart) and sent to the drafts API.
class DraftNotifier extends Notifier<RequestDraft> {
  static const storageKey = 'post.draft.v1';

  @override
  RequestDraft build() {
    final raw = ref.read(sharedPrefsProvider).getString(storageKey);
    if (raw == null) return const RequestDraft();
    try {
      return RequestDraft.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      return const RequestDraft();
    }
  }

  void update(RequestDraft Function(RequestDraft) f) {
    state = f(state);
    ref
        .read(sharedPrefsProvider)
        .setString(storageKey, jsonEncode(state.toJson()));
    ref.read(postRepositoryProvider).saveDraft(state);
  }

  /// After a successful publish the draft is done.
  void clear() {
    state = const RequestDraft();
    ref.read(sharedPrefsProvider).remove(storageKey);
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

  // Previews and the raise-price editor must not overwrite the saved draft.
  @override
  void update(RequestDraft Function(RequestDraft) f) => state = f(state);

  @override
  void clear() {}
}
