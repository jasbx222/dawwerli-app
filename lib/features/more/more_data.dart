import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/catalog.dart';
import '../../core/api/token_store.dart';
import '../../core/storage/prefs.dart';
import '../home/domain/home_models.dart';

/// Category tile data (GET /api/v1/categories).
class CatalogCategory {
  const CatalogCategory(this.id, this.name, this.image, {this.slug = ''});
  final String id;
  final String name;
  final ImageRef image;

  /// Stable key (API slug) used for the SVG icon.
  final String slug;
}

final catalogCategoriesProvider = Provider<List<CatalogCategory>>(
  (ref) => [
    for (final c
        in ref.watch(catalogProvider).value?.categories ??
            const <CatalogCategoryRef>[])
      CatalogCategory('${c.id}', c.name, c.image, slug: c.slug),
  ],
);

extension CatalogCategoryLookup on List<CatalogCategory> {
  CatalogCategory byId(String id) =>
      where((c) => c.id == id).firstOrNull ?? const CatalogCategory('', '', '');

  /// Slug for a category display name (pages list categories by name).
  String? slugOf(String name) => where((c) => c.name == name).firstOrNull?.slug;
}

/// Public page profile (GET /api/v1/pages/{id}); phone never included.
class PageProfile {
  const PageProfile({
    required this.id,
    required this.name,
    required this.rating,
    required this.deals,
    required this.governorate,
    required this.deliversTo,
    required this.categories,
    required this.replyMinutes,
    required this.memberSince,
    this.image,
  });
  final String id;
  final String name;
  final double rating;
  final int deals;
  final String governorate;
  final int deliversTo;
  final List<String> categories;
  final int replyMinutes;
  final String memberSince;
  final ImageRef? image;

  PageSummary get summary => PageSummary(
    id: id,
    name: name,
    rating: rating,
    deals: deals,
    image: image,
  );
}

final pageProfileProvider = FutureProvider.autoDispose
    .family<PageProfile, String>((ref, id) async {
      final j = await ref
          .watch(apiClientProvider)
          .get<Map<String, dynamic>>('/api/v1/pages/$id');
      final govs = j.list<String>('governorates');
      return PageProfile(
        id: j.s('id'),
        name: j.s('name'),
        rating: j.d('rating'),
        deals: j.i('deals'),
        governorate: govs.firstOrNull ?? '',
        deliversTo: govs.length,
        categories: j.list<String>('categories'),
        replyMinutes: j.i('replyMinutes'),
        memberSince: '${j.i('memberSince')}',
        image: j.os('image'),
      );
    });

/// Verified pages of a category in my governorate (paid «مُموّل» first, then organic).
final categoryPagesProvider = FutureProvider.autoDispose
    .family<List<PageSummary>, String>((ref, categoryId) async {
      final cat = await ref.watch(catalogProvider.future);
      final gov = cat.governorateId(ref.watch(regionProvider).governorate);
      final api = ref.watch(apiClientProvider);
      final id = int.tryParse(categoryId) ?? cat.category(categoryId)?.id;
      final j = await api.get<Map<String, dynamic>>(
        '/api/v1/pages/featured',
        query: {'categoryId': id, 'governorateId': gov},
      );
      List<Map<String, dynamic>> slot = const [];
      try {
        slot = asList(
          await api.get<List<dynamic>>(
            '/api/v1/ads',
            query: {
              'slot': 'featuredPage',
              'governorateId': gov,
              'categoryId': ?id,
            },
          ),
        );
      } on ApiException {
        slot = const [];
      }
      return featuredWithPaid([
        for (final p in j.l('pages')) pageSummaryFromJson(p),
      ], slot);
    });

PageSummary pageSummaryFromJson(Map<String, dynamic> p) => PageSummary(
  id: p.s('id'),
  name: p.s('name'),
  rating: p.d('rating'),
  deals: p.i('deals'),
  image: p.os('image'),
  isAd: p.b('isAd'),
);

/// Paid «صفحة مميزة» first, then organic pages. Same page is not repeated.
List<PageSummary> featuredWithPaid(
  List<PageSummary> organic,
  List<Map<String, dynamic>> slot,
) {
  final paidIds = <String>{};
  final paid = <PageSummary>[];
  for (final a in slot) {
    final id = a.s('pageId');
    if (id.isEmpty || !paidIds.add(id)) continue;
    final existing = organic.where((p) => p.id == id).firstOrNull;
    paid.add(
      PageSummary(
        id: id,
        name: existing?.name.isNotEmpty == true
            ? existing!.name
            : a.s('pageName'),
        rating: existing?.rating ?? 0,
        deals: existing?.deals ?? 0,
        image: existing?.image ?? a.os('image'),
        isAd: true,
        adId: a.os('id'),
      ),
    );
  }
  return [
    ...paid,
    for (final p in organic)
      if (p.isAd && paidIds.add(p.id)) p,
    for (final p in organic)
      if (!p.isAd && !paidIds.contains(p.id)) p,
  ];
}

FeedItem feedItemFromJson(Map<String, dynamic> f) => FeedItem(
  category: f.s('category'),
  governorate: f.s('governorate'),
  offers: f.i('offers'),
  image: f.os('image') ?? '',
);

/// Anonymized activity (GET /api/v1/home/feed): category + governorate + offers.
final fullFeedProvider = FutureProvider.autoDispose<List<FeedItem>>((
  ref,
) async {
  final list = asList(
    await ref.watch(apiClientProvider).get<List<dynamic>>('/api/v1/home/feed'),
  );
  return [for (final f in list) feedItemFromJson(f)];
});

/// Legal text (GET /api/v1/legal/{terms|privacy}) as (title, body) sections.
final legalProvider = FutureProvider.family<List<(String, String)>, String>((
  ref,
  doc,
) async {
  final md = await ref
      .watch(apiClientProvider)
      .get<String>('/api/v1/legal/$doc');
  final out = <(String, String)>[];
  for (final block
      in md
          .split(RegExp(r'^## ', multiLine: true))
          .where((b) => b.trim().isNotEmpty)) {
    final lines = block.trim().split('\n');
    out.add((lines.first.trim(), lines.skip(1).join('\n').trim()));
  }
  return out;
});

/// Governorate + area shown on home and «حسابي» (saved on the device; PUT /me later).
class Region {
  const Region(this.governorate, this.area, {this.explicit = false});
  final String governorate;
  final String area;

  /// True once the user picked a governorate on this device («منطقتي»).
  /// Until then home follows the governorate on the signed-in profile
  /// (server side), and guests get the all-Iraq headline.
  final bool explicit;
  String get label => area.isEmpty ? governorate : '$governorate · $area';
}

class RegionNotifier extends Notifier<Region> {
  @override
  Region build() {
    final p = ref.watch(sharedPrefsProvider);
    final gov = p.getString('region.gov');
    return Region(
      gov ?? 'بغداد',
      p.getString('region.area') ?? 'الكرادة',
      explicit: gov != null,
    );
  }

  Future<void> save(String gov, String area) async {
    final p = ref.read(sharedPrefsProvider);
    p.setString('region.gov', gov);
    p.setString('region.area', area);
    state = Region(gov, area, explicit: true);
    if (!ref.read(tokenStoreProvider).signedIn) return;
    final id = (await ref.read(catalogProvider.future)).governorateId(gov);
    await ref.read(apiClientProvider).put<void>('/api/v1/me/region', {
      'governorateId': id,
      'area': area,
    });
  }
}

final regionProvider = NotifierProvider<RegionNotifier, Region>(
  RegionNotifier.new,
);

/// Customer notification switches (stored on device; synced with POST /devices later).
enum NotifPref { offers, status, delivery, expired, news }

extension NotifPrefText on NotifPref {
  String get title => switch (this) {
    NotifPref.offers => 'عروض جديدة على طلبي',
    NotifPref.status => 'حالة الطلب والصفحة اللي اخترتها',
    NotifPref.delivery => 'سؤال «وصلك؟» بعد التوصيل',
    NotifPref.expired => 'توسيع الطلب أو انتهاؤه',
    NotifPref.news => 'عروض المناسبات والإعلانات',
  };
  String get sub => switch (this) {
    NotifPref.offers => 'أول ما توصل عرض من صفحة',
    NotifPref.status => 'ردّت الصفحة، ما ردّت، وتحديثات الشكوى',
    NotifPref.delivery => 'حتى تأكد الاستلام وتقيّم',
    NotifPref.expired => 'بعد 15 دقيقة بدون عروض أو 24 ساعة',
    NotifPref.news => 'رمضان، العيد، رجعة المدارس',
  };

  /// Order-critical switches can't be turned off.
  bool get locked => this == NotifPref.status;
}

class NotifPrefsNotifier extends Notifier<Map<NotifPref, bool>> {
  @override
  Map<NotifPref, bool> build() {
    final p = ref.watch(sharedPrefsProvider);
    return {
      for (final n in NotifPref.values)
        n: p.getBool('notif.${n.name}') ?? n != NotifPref.news,
    };
  }

  void toggle(NotifPref n) {
    if (n.locked) return;
    final v = !(state[n] ?? true);
    ref.read(sharedPrefsProvider).setBool('notif.${n.name}', v);
    state = {...state, n: v};
  }
}

final notifPrefsProvider =
    NotifierProvider<NotifPrefsNotifier, Map<NotifPref, bool>>(
      NotifPrefsNotifier.new,
    );

/// Blocked pages (GET/POST/DELETE /api/v1/blocks); they never see my requests.
/// State holds page ids; [nameOf] gives the display name.
class BlockedNotifier extends Notifier<List<String>> {
  final _names = <String, String>{};

  @override
  List<String> build() {
    _load();
    return const [];
  }

  ApiClient get _api => ref.read(apiClientProvider);

  Future<void> _load() async {
    if (!ref.read(tokenStoreProvider).signedIn) return;
    try {
      final list = asList(await _api.get<List<dynamic>>('/api/v1/blocks'));
      for (final b in list) {
        _names[b.os('pageId') ?? b.s('userId')] = b.s('name');
      }
      state = [for (final b in list) b.os('pageId') ?? b.s('userId')];
    } on ApiException {
      // Keep the last known list.
    }
  }

  String nameOf(String id) => _names[id] ?? '';

  Future<void> block(String id, {String name = ''}) async {
    if (state.contains(id)) return;
    await _api.post<void>('/api/v1/blocks', {'pageId': id});
    _names[id] = name;
    state = [...state, id];
  }

  Future<void> unblock(String id) async {
    await _api.delete<void>('/api/v1/blocks/$id');
    state = [...state]..remove(id);
  }
}

final blockedProvider = NotifierProvider<BlockedNotifier, List<String>>(
  BlockedNotifier.new,
);
