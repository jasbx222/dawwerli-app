import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../guest/guest.dart';
import '../../home/domain/home_models.dart';

/// Product ranking lists served by the discovery endpoints.
enum ProductRanking {
  bestSelling(
    'best-selling',
    'الأكثر مبيعاً',
    'المنتجات اللي الناس اشترتها أكثر شي',
  ),
  highestRated(
    'highest-rated',
    'الأعلى تقييماً',
    'منتجات زباينها عطوها أعلى تقييم',
  );

  const ProductRanking(this.path, this.title, this.subtitle);
  final String path;
  final String title;
  final String subtitle;

  static ProductRanking? fromPath(String? p) {
    for (final r in values) {
      if (r.path == p) return r;
    }
    return null;
  }
}

/// DiscoverProductDto → [HomeProduct] (+ how many were sold).
HomeProduct discoverProductFromJson(Map<String, dynamic> j) => HomeProduct(
  pageId: j.s('pageId'),
  pageName: j.s('pageName'),
  id: j.s('id'),
  name: j.s('name'),
  price: j.i('price'),
  image: j.os('imageUrl') ?? '',
  description: j.s('description'),
  stock: j.i('stock'),
  available: j.containsKey('available') ? j.b('available') : j.i('stock') > 0,
  rating: j.d('rating'),
  ratingCount: j.i('ratingCount'),
  sold: j.i('sold'),
);

/// One page of a paged list.
class Paged<T> {
  const Paged(this.items, this.total);
  final List<T> items;
  final int total;
}

Paged<T> pagedFromJson<T>(Object? raw, T Function(Map<String, dynamic>) item) {
  if (raw is Map) {
    final j = raw.cast<String, dynamic>();
    final items = [for (final e in j.l('items')) item(e)];
    return Paged(items, j.containsKey('total') ? j.i('total') : items.length);
  }
  final items = [for (final e in asList(raw)) item(e)];
  return Paged(items, items.length);
}

/// A list that grows page by page (infinite scroll).
class PagedState<T> {
  const PagedState({
    this.items = const [],
    this.total = 0,
    this.page = 0,
    this.loading = false,
    this.error,
  });
  final List<T> items;
  final int total;
  final int page;
  final bool loading;
  final Object? error;

  bool get done => page > 0 && items.length >= total;
  bool get firstLoad => page == 0 && loading;
  bool get empty => page > 0 && items.isEmpty;

  PagedState<T> copyWith({
    List<T>? items,
    int? total,
    int? page,
    bool? loading,
    Object? error,
  }) => PagedState(
    items: items ?? this.items,
    total: total ?? this.total,
    page: page ?? this.page,
    loading: loading ?? this.loading,
    error: error,
  );
}

/// Shared load-more logic; subclasses fetch one page.
abstract class PagedNotifier<T> extends Notifier<PagedState<T>> {
  static const pageSize = 20;

  Future<Paged<T>> fetch(int page);

  @override
  PagedState<T> build() {
    Future.microtask(loadMore);
    return const PagedState(loading: true);
  }

  var _busy = false;

  Future<void> loadMore() async {
    final s = state;
    if (_busy || s.done) return;
    _busy = true;
    state = s.copyWith(loading: true);
    try {
      final next = s.page + 1;
      final r = await fetch(next);
      if (!ref.mounted) return;
      state = PagedState(
        items: [...state.items, ...r.items],
        total: r.total,
        page: next,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(loading: false, error: e);
    } finally {
      _busy = false;
    }
  }

  Future<void> reload() async {
    if (_busy) return;
    state = const PagedState(loading: true);
    await loadMore();
  }
}

/// «عرض المزيد» grid of a ranking.
final rankedProductsProvider = NotifierProvider.autoDispose
    .family<RankedProductsNotifier, PagedState<HomeProduct>, ProductRanking>(
      RankedProductsNotifier.new,
    );

class RankedProductsNotifier extends PagedNotifier<HomeProduct> {
  RankedProductsNotifier(this.ranking);
  final ProductRanking ranking;

  @override
  Future<Paged<HomeProduct>> fetch(int page) async => pagedFromJson(
    await ref
        .read(apiClientProvider)
        .get<Object?>(
          '/api/v1/products/${ranking.path}',
          query: {'page': page, 'pageSize': PagedNotifier.pageSize},
        ),
    discoverProductFromJson,
  );
}

/// The home slider of a ranking: the first 10.
final rankingStripProvider = FutureProvider.autoDispose
    .family<List<HomeProduct>, ProductRanking>((ref, ranking) async {
      final raw = await ref
          .watch(apiClientProvider)
          .get<Object?>(
            '/api/v1/products/${ranking.path}',
            query: {'page': 1, 'pageSize': 10},
          );
      return pagedFromJson(raw, discoverProductFromJson).items;
    });

// ───────────────────────── Pages ─────────────────────────

/// PageCardDto: a page in «الصفحات المميزة» and the pages directory.
class PageCard {
  const PageCard({
    required this.id,
    required this.name,
    this.image,
    this.bio = '',
    this.rating = 0,
    this.ratingCount = 0,
    this.deals = 0,
    this.trusted = false,
    this.productCount = 0,
    this.followerCount = 0,
    this.isFollowing = false,
    this.categories = const [],
    this.previews = const [],
    this.featuredOrder,
  });
  final String id;
  final String name;
  final String? image;
  final String bio;
  final double rating;
  final int ratingCount;
  final int deals;
  final bool trusted;
  final int productCount;
  final int followerCount;
  final bool isFollowing;
  final List<String> categories;
  final List<String> previews;
  final int? featuredOrder;

  factory PageCard.fromJson(Map<String, dynamic> j) => PageCard(
    id: j.s('id'),
    name: j.s('name'),
    image: j.os('image'),
    bio: j.os('bio') ?? '',
    rating: j.d('rating'),
    ratingCount: j.i('ratingCount'),
    deals: j.i('deals'),
    trusted: j.b('trusted'),
    productCount: j.i('productCount'),
    followerCount: j.i('followerCount'),
    isFollowing: j.b('isFollowing'),
    categories: [for (final c in (j['categories'] as List? ?? const [])) '$c'],
    previews: [
      for (final p in (j['previews'] as List? ?? const []))
        if (p is String && p.isNotEmpty) p,
    ],
    featuredOrder: j.oi('featuredOrder'),
  );
}

/// «الصفحات المميزة» on home: the top 5.
final topPagesProvider = FutureProvider.autoDispose<List<PageCard>>((
  ref,
) async {
  final raw = await ref
      .watch(apiClientProvider)
      .get<Object?>('/api/v1/pages/top', query: {'take': 5});
  return pagedFromJson(raw, PageCard.fromJson).items.take(5).toList();
});

/// Filters of the «الصفحات» tab.
typedef DirectoryQuery = ({String q, int? categoryId, bool following});

final pagesDirectoryProvider = NotifierProvider.autoDispose
    .family<PagesDirectoryNotifier, PagedState<PageCard>, DirectoryQuery>(
      PagesDirectoryNotifier.new,
    );

class PagesDirectoryNotifier extends PagedNotifier<PageCard> {
  PagesDirectoryNotifier(this.query);
  final DirectoryQuery query;

  @override
  Future<Paged<PageCard>> fetch(int page) async => pagedFromJson(
    await ref
        .read(apiClientProvider)
        .get<Object?>(
          '/api/v1/pages/directory',
          query: {
            if (query.q.trim().isNotEmpty) 'q': query.q.trim(),
            'categoryId': ?query.categoryId,
            if (query.following) 'following': true,
            'page': page,
            'pageSize': PagedNotifier.pageSize,
          },
        ),
    PageCard.fromJson,
  );
}

/// PageProfileDto (GET /pages/{id}/profile).
class PageProfileV2 {
  const PageProfileV2({
    required this.id,
    required this.name,
    this.image,
    this.bio = '',
    this.rating = 0,
    this.ratingCount = 0,
    this.deals = 0,
    this.trusted = false,
    this.categories = const [],
    this.governorates = const [],
    this.memberSince = 0,
    this.productCount = 0,
    this.followerCount = 0,
    this.orderCount = 0,
    this.isFollowing = false,
  });
  final String id;
  final String name;
  final String? image;
  final String bio;
  final double rating;
  final int ratingCount;
  final int deals;
  final bool trusted;
  final List<String> categories;
  final List<String> governorates;
  final int memberSince;
  final int productCount;
  final int followerCount;
  final int orderCount;
  final bool isFollowing;

  factory PageProfileV2.fromJson(Map<String, dynamic> j) => PageProfileV2(
    id: j.s('id'),
    name: j.s('name'),
    image: j.os('image'),
    bio: j.os('bio') ?? '',
    rating: j.d('rating'),
    ratingCount: j.i('ratingCount'),
    deals: j.i('deals'),
    trusted: j.b('trusted'),
    categories: [for (final c in (j['categories'] as List? ?? const [])) '$c'],
    governorates: [
      for (final c in (j['governorates'] as List? ?? const [])) '$c',
    ],
    memberSince: j.i('memberSince'),
    productCount: j.i('productCount'),
    followerCount: j.i('followerCount'),
    orderCount: j.i('orderCount'),
    isFollowing: j.b('isFollowing'),
  );
}

final pageProfileV2Provider = FutureProvider.autoDispose
    .family<PageProfileV2, String>((ref, id) async {
      final j = await ref
          .watch(apiClientProvider)
          .get<Map<String, dynamic>>('/api/v1/pages/$id/profile');
      return PageProfileV2.fromJson(j);
    });

/// Follow state the customer changed in this session, by page id. Screens
/// show it over what the server sent, so a follow shows everywhere at once.
typedef FollowState = ({bool following, int followers});

final followProvider =
    NotifierProvider<FollowNotifier, Map<String, FollowState>>(
      FollowNotifier.new,
    );

class FollowNotifier extends Notifier<Map<String, FollowState>> {
  @override
  Map<String, FollowState> build() {
    ref.watch(guestProvider);
    return const {};
  }

  FollowState resolve(String pageId, bool following, int followers) =>
      state[pageId] ?? (following: following, followers: followers);

  /// Optimistic follow / unfollow; the server's count wins, a failure rolls back.
  Future<void> toggle(String pageId, FollowState current) async {
    final next = (
      following: !current.following,
      followers: (current.followers + (current.following ? -1 : 1)).clamp(
        0,
        1 << 31,
      ),
    );
    state = {...state, pageId: next};
    final api = ref.read(apiClientProvider);
    try {
      final path = '/api/v1/pages/$pageId/follow';
      final j = next.following
          ? await api.post<Map<String, dynamic>>(path)
          : await api.delete<Map<String, dynamic>>(path);
      state = {
        ...state,
        pageId: (
          following: j.b('isFollowing'),
          followers: j.i('followerCount'),
        ),
      };
    } catch (_) {
      state = {...state, pageId: current};
      rethrow;
    }
  }
}

/// Unread notifications for the bell badge. Reads the list without marking
/// it read (the notifications screen does that).
final unreadNotificationsProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  if (ref.watch(guestProvider)) return 0;
  try {
    final raw = await ref
        .watch(apiClientProvider)
        .get<Object?>('/api/v1/notifications');
    final list = raw is Map ? asList(raw['items']) : asList(raw);
    return list.where((n) => !n.b('read')).length;
  } catch (_) {
    return 0;
  }
});
