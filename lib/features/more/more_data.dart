import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/prefs.dart';
import '../home/domain/home_models.dart';

const _img = 'assets/images/mock';

/// Full category catalogue (GET /api/v1/categories) until the API lands.
class CatalogCategory {
  const CatalogCategory(this.id, this.name, this.image);
  final String id;
  final String name;
  final ImageRef image;
}

const catalogCategories = [
  CatalogCategory('phones', 'موبايلات', '$_img/phone.jpg'),
  CatalogCategory('shoes', 'أحذية', '$_img/shoe.jpg'),
  CatalogCategory('clothes', 'ملابس', '$_img/jacket.jpg'),
  CatalogCategory('dresses', 'فساتين', '$_img/dress.jpg'),
  CatalogCategory('perfumes', 'عطور', '$_img/perfume.jpg'),
  CatalogCategory('care', 'عناية', '$_img/cosmetics.jpg'),
  CatalogCategory('watches', 'ساعات', '$_img/watch.jpg'),
  CatalogCategory('eid', 'هدوم العيد', '$_img/shirt.jpg'),
  CatalogCategory('home', 'أغراض البيت', '$_img/lamp.jpg'),
];

CatalogCategory categoryById(String id) => catalogCategories.firstWhere(
  (c) => c.id == id,
  orElse: () => catalogCategories.first,
);

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

const _pages = {
  'p1': PageProfile(
    id: 'p1',
    name: 'ستايل بغداد',
    rating: 4.8,
    deals: 120,
    governorate: 'بغداد',
    deliversTo: 6,
    categories: ['أحذية', 'ملابس', 'ساعات'],
    replyMinutes: 6,
    memberSince: '2026',
    image: '$_img/shoe.jpg',
  ),
  'p2': PageProfile(
    id: 'p2',
    name: 'موبايل زون',
    rating: 4.7,
    deals: 86,
    governorate: 'بغداد',
    deliversTo: 18,
    categories: ['موبايلات'],
    replyMinutes: 9,
    memberSince: '2026',
    image: '$_img/phone.jpg',
  ),
  'p3': PageProfile(
    id: 'p3',
    name: 'عطور الشرق',
    rating: 4.9,
    deals: 74,
    governorate: 'بغداد',
    deliversTo: 4,
    categories: ['عطور', 'عناية'],
    replyMinutes: 5,
    memberSince: '2026',
    image: '$_img/perfume.jpg',
  ),
  'p4': PageProfile(
    id: 'p4',
    name: 'رياضة الكرادة',
    rating: 4.9,
    deals: 210,
    governorate: 'بغداد',
    deliversTo: 3,
    categories: ['أحذية', 'ملابس'],
    replyMinutes: 4,
    memberSince: '2026',
    image: '$_img/shoe.jpg',
  ),
  'p5': PageProfile(
    id: 'p5',
    name: 'حذاء المنصور',
    rating: 4.6,
    deals: 58,
    governorate: 'بغداد',
    deliversTo: 2,
    categories: ['أحذية'],
    replyMinutes: 12,
    memberSince: '2026',
    image: '$_img/shoe.jpg',
  ),
  'p6': PageProfile(
    id: 'p6',
    name: 'بوتيك ريم',
    rating: 4.8,
    deals: 88,
    governorate: 'بغداد',
    deliversTo: 5,
    categories: ['فساتين', 'ملابس'],
    replyMinutes: 8,
    memberSince: '2026',
    image: '$_img/dress.jpg',
  ),
  'p7': PageProfile(
    id: 'p7',
    name: 'ساعات النخبة',
    rating: 4.7,
    deals: 41,
    governorate: 'بغداد',
    deliversTo: 18,
    categories: ['ساعات'],
    replyMinutes: 10,
    memberSince: '2026',
    image: '$_img/watch.jpg',
  ),
  'p8': PageProfile(
    id: 'p8',
    name: 'بيتي',
    rating: 4.9,
    deals: 64,
    governorate: 'بغداد',
    deliversTo: 3,
    categories: ['أغراض البيت'],
    replyMinutes: 15,
    memberSince: '2026',
    image: '$_img/lamp.jpg',
  ),
};

PageProfile pageById(String id) => _pages[id] ?? _pages['p1']!;

/// Mock lookup by display name (stories carry names only in the mock).
String pageIdByName(String name) => _pages.values
    .firstWhere((p) => p.name == name, orElse: () => _pages['p1']!)
    .id;

/// Pages in a category for the customer's governorate (organic, by rating).
List<PageProfile> pagesInCategory(String categoryName) =>
    _pages.values.where((p) => p.categories.contains(categoryName)).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

/// Anonymized activity (GET /api/v1/home/feed): category + governorate + offers.
const fullFeed = [
  FeedItem(
    category: 'موبايلات',
    governorate: 'بغداد',
    offers: 4,
    image: '$_img/phone.jpg',
  ),
  FeedItem(
    category: 'ملابس',
    governorate: 'البصرة',
    offers: 2,
    image: '$_img/jacket.jpg',
  ),
  FeedItem(
    category: 'عطور',
    governorate: 'أربيل',
    offers: 5,
    image: '$_img/perfume.jpg',
  ),
  FeedItem(
    category: 'أحذية',
    governorate: 'بغداد',
    offers: 3,
    image: '$_img/shoe.jpg',
  ),
  FeedItem(
    category: 'فساتين',
    governorate: 'نينوى',
    offers: 1,
    image: '$_img/dress.jpg',
  ),
  FeedItem(
    category: 'ساعات',
    governorate: 'النجف',
    offers: 4,
    image: '$_img/watch.jpg',
  ),
  FeedItem(
    category: 'أغراض البيت',
    governorate: 'كربلاء',
    offers: 2,
    image: '$_img/lamp.jpg',
  ),
  FeedItem(
    category: 'عناية',
    governorate: 'بابل',
    offers: 5,
    image: '$_img/cosmetics.jpg',
  ),
];

/// Governorate + area shown on home and «حسابي» (saved on the device; PUT /me later).
class Region {
  const Region(this.governorate, this.area);
  final String governorate;
  final String area;
  String get label => area.isEmpty ? governorate : '$governorate · $area';
}

class RegionNotifier extends Notifier<Region> {
  @override
  Region build() {
    final p = ref.watch(sharedPrefsProvider);
    return Region(
      p.getString('region.gov') ?? 'بغداد',
      p.getString('region.area') ?? 'الكرادة',
    );
  }

  void save(String gov, String area) {
    final p = ref.read(sharedPrefsProvider);
    p.setString('region.gov', gov);
    p.setString('region.area', area);
    state = Region(gov, area);
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

/// Blocked pages (POST/DELETE /api/v1/blocks); they never see my requests.
class BlockedNotifier extends Notifier<List<String>> {
  @override
  List<String> build() =>
      ref.watch(sharedPrefsProvider).getStringList('blocked.pages') ??
      const ['p5', 'p8'];

  void _save(List<String> v) {
    ref.read(sharedPrefsProvider).setStringList('blocked.pages', v);
    state = v;
  }

  void block(String id) => state.contains(id) ? null : _save([...state, id]);
  void unblock(String id) => _save([...state]..remove(id));
}

final blockedProvider = NotifierProvider<BlockedNotifier, List<String>>(
  BlockedNotifier.new,
);
