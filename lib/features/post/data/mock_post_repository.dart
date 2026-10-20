import '../domain/post_repository.dart';
import '../domain/request_draft.dart';

class MockPostRepository implements PostRepository {
  MockPostRepository({this.openCount = 2, this.online = true});

  int openCount;
  bool online;
  RequestDraft? lastDraft;

  @override
  Future<List<CategoryOption>> suggestCategories(RequestDraft draft) async =>
      const [
        CategoryOption('أحذية', emoji: '👟'),
        CategoryOption('ملابس'),
        CategoryOption('رياضة'),
      ];

  @override
  Future<DetailSchema> detailSchema(String category) async =>
      const DetailSchema(
        hint: 'الأحذية تحتاج قياس ولون',
        sizes: ['39', '40', '41', '42', '43', '44', '45'],
        colors: ['أسود', 'أبيض', 'رمادي', 'أزرق', 'أحمر'],
        priceSuggestions: [35000, 45000, 60000],
      );

  @override
  Future<int> openRequestsCount() async => openCount;

  @override
  Future<void> saveDraft(RequestDraft draft) async => lastDraft = draft;

  @override
  Future<PublishResult> publish(RequestDraft draft) async {
    final errors = PostRules.validate(draft, openCount: openCount);
    // Mock moderation: a few banned keywords (real check is server-side).
    if (RegExp('سلاح|مسدس|دواء|أدوية').hasMatch(draft.description)) {
      errors.add(PostError.prohibited);
    }
    if (errors.isNotEmpty) return Rejected(errors);
    if (!online) return const QueuedOffline();
    openCount++;
    return const Published('req_mock_1');
  }
}
