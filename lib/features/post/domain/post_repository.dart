import 'request_draft.dart';

sealed class PublishResult {
  const PublishResult();
}

class Published extends PublishResult {
  const Published(this.requestId);
  final String requestId;
}

class Rejected extends PublishResult {
  const Rejected(this.errors);
  final Set<PostError> errors;
}

/// Offline: the draft is queued and sent automatically when the connection returns.
class QueuedOffline extends PublishResult {
  const QueuedOffline();
}

/// Mirrors POST /v1/requests/classify, GET /v1/categories/{id}/schema,
/// PUT /v1/requests/draft, GET /v1/requests/open-count, POST /v1/requests.
abstract interface class PostRepository {
  Future<List<CategoryOption>> suggestCategories(RequestDraft draft);
  Future<DetailSchema> detailSchema(String category);
  Future<int> openRequestsCount();
  Future<void> saveDraft(RequestDraft draft);
  Future<PublishResult> publish(RequestDraft draft);
}
