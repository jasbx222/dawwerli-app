import '../../../core/api/api_client.dart';
import '../../../core/api/catalog.dart';
import '../../../core/api/media.dart';
import '../domain/post_repository.dart';
import '../domain/request_draft.dart';

/// POST /categories/suggest, GET /categories (schema), GET /requests/open-count,
/// POST /media + POST /requests. The server re-checks every rule.
class ApiPostRepository implements PostRepository {
  const ApiPostRepository(this.api, this.catalog);
  final ApiClient api;
  final Future<Catalog> catalog;

  static const _rejected = 'request.invalid';
  static const _conditions = {
    ItemCondition.brandNew: 'brandNew',
    ItemCondition.used: 'used',
    ItemCondition.any: 'any',
  };

  @override
  Future<List<CategoryOption>> suggestCategories(RequestDraft draft) async {
    final cat = await catalog;
    final ids = asList(
      await api.post<List<dynamic>>('/api/v1/categories/suggest', {'text': draft.description}),
    );
    return [
      for (final id in ids.map((e) => e as Object))
        if (cat.categoryById((id as num).toInt()) case final c?)
          CategoryOption(c.name, emoji: c.emoji),
    ];
  }

  @override
  Future<DetailSchema> detailSchema(String category) async {
    final s = (await catalog).category(category)?.schema;
    return DetailSchema(
      hint: s?.hint ?? '',
      sizes: s?.sizes ?? const [],
      colors: s?.colors ?? const [],
      priceSuggestions: s?.prices ?? const [],
    );
  }

  @override
  Future<int> openRequestsCount() async =>
      (await api.get<Map<String, dynamic>>('/api/v1/requests/open-count')).i('count');

  /// Drafts live on the device (DraftNotifier); nothing to sync.
  @override
  Future<void> saveDraft(RequestDraft draft) async {}

  @override
  Future<PublishResult> publish(RequestDraft draft) async {
    final cat = await catalog;
    try {
      final key = draft.mode == InputMode.voice
          ? await uploadImage(api, draft.voice, 'requests')
          : await uploadImage(api, draft.photo, 'requests') ??
                await uploadImage(api, draft.voice, 'requests');
      final j = await api.post<Map<String, dynamic>>('/api/v1/requests', {
        'mode': draft.mode.name,
        'mediaKey': key,
        'description': draft.description,
        'voiceSeconds': draft.voiceSeconds,
        'categoryId': cat.category(draft.category ?? '')?.id ?? 0,
        'size': draft.size,
        'color': draft.color,
        'condition': _conditions[draft.condition],
        'maxPrice': draft.maxPrice ?? 0,
        'governorateId': cat.governorateId(draft.governorate) ?? 0,
        'readyToBuy': draft.readyToBuy,
      });
      return Published(j.s('id'));
    } on ApiException catch (e) {
      if (e.offline) return const QueuedOffline();
      if (e.code != _rejected) rethrow;
      return Rejected({
        for (final c in e.errors)
          ?PostError.values.where((p) => p.name == c).firstOrNull ??
              (c == 'notReady' ? PostError.incomplete : null),
      });
    }
  }
}
