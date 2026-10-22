import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../store/data/store_data.dart';

/// A product order placed with this page's store, with the customer details
/// the API allows (the phone is dropped once the order is closed).
class PageStoreOrder {
  const PageStoreOrder(this.order, {this.customerName, this.customerPhone});
  final StoreOrder order;
  final String? customerName;
  final String? customerPhone;

  factory PageStoreOrder.fromJson(Map<String, dynamic> j) => PageStoreOrder(
    StoreOrder.fromJson(j.m('order')),
    customerName: j.os('customerName'),
    customerPhone: j.os('customerPhone'),
  );
}

/// List filters on «طلباتي»; `code` is what the API takes in `?status=`.
enum StoreOrderFilter {
  all(null, 'الكل'),
  active('active', 'الشغّالة'),
  fresh('new', 'الجديدة'),
  delivery('outForDelivery', 'بالتوصيل'),
  closed('closed', 'المنتهية');

  const StoreOrderFilter(this.code, this.label);
  final String? code;
  final String label;
}

/// Next statuses the page can move an order to (StoreOrderFlow).
List<String> nextStoreStatuses(String status) => switch (status) {
  'new' => const ['accepted', 'rejected'],
  'accepted' => const ['out_for_delivery', 'cancelled'],
  'out_for_delivery' => const ['delivered', 'cancelled'],
  _ => const [],
};

/// app snake_case → API camelCase ("out_for_delivery" → "outForDelivery").
String storeStatusApi(String code) =>
    code.replaceAllMapped(RegExp('_([a-z])'), (m) => m[1]!.toUpperCase());

class PageStoreOrdersRepo {
  const PageStoreOrdersRepo(this._api);
  final ApiClient _api;

  static const _base = '/api/v1/pages/me/store-orders';

  Future<({List<PageStoreOrder> items, int total})> list(
    StoreOrderFilter f, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final j = await _api.get<Map<String, dynamic>>(
      _base,
      query: {'status': ?f.code, 'page': page, 'pageSize': pageSize},
    );
    return (
      items: [for (final o in j.l('items')) PageStoreOrder.fromJson(o)],
      total: j.i('total'),
    );
  }

  Future<PageStoreOrder> get(String id) async => PageStoreOrder.fromJson(
    await _api.get<Map<String, dynamic>>('$_base/$id'),
  );

  Future<PageStoreOrder> move(
    String id,
    String status, {
    String? reason,
    String? courierId,
  }) async => PageStoreOrder.fromJson(
    await _api.post<Map<String, dynamic>>('$_base/$id/status', {
      'status': storeStatusApi(status),
      'reason': ?reason,
      'courierId': ?courierId,
    }),
  );
}

/// One of the page's own delivery people; shown to the customer once the
/// order is out for delivery.
class Courier {
  const Courier({
    required this.id,
    required this.name,
    required this.phone,
    this.active = true,
  });
  final String id;
  final String name;
  final String phone;
  final bool active;

  factory Courier.fromJson(Map<String, dynamic> j) => Courier(
    id: j.s('id'),
    name: j.s('name'),
    phone: j.s('phone'),
    active: j['active'] as bool? ?? true,
  );
}

class CouriersRepo {
  const CouriersRepo(this._api);
  final ApiClient _api;

  static const _base = '/api/v1/pages/me/couriers';

  Future<List<Courier>> list() async {
    final j = await _api.get<Object?>(_base);
    final items = j is Map
        ? (j['items'] as List? ?? const [])
        : (j as List? ?? const []);
    return [
      for (final c in items.whereType<Map>())
        Courier.fromJson(c.cast<String, dynamic>()),
    ];
  }

  Future<Courier> create(String name, String phone) async => Courier.fromJson(
    await _api.post<Map<String, dynamic>>(_base, {
      'name': name,
      'phone': phone,
      'active': true,
    }),
  );

  Future<Courier> update(
    Courier c, {
    String? name,
    String? phone,
    bool? active,
  }) async => Courier.fromJson(
    await _api.put<Map<String, dynamic>>('$_base/${c.id}', {
      'name': name ?? c.name,
      'phone': phone ?? c.phone,
      'active': active ?? c.active,
    }),
  );

  Future<void> delete(String id) => _api.delete<Object?>('$_base/$id');
}

final couriersRepoProvider = Provider<CouriersRepo>(
  (ref) => CouriersRepo(ref.watch(apiClientProvider)),
);

final couriersProvider = FutureProvider.autoDispose<List<Courier>>(
  (ref) => ref.watch(couriersRepoProvider).list(),
);

/// Arabic text for the page-order / courier API errors.
const pageOrderErrorText = <String, String>{
  'order.contact': 'ممنوع تكتب رقم تلفون أو يوزر (@) أو رابط. كل التواصل والاتفاق يصير داخل دوّرلي.',
  'order.not_out': 'لازم يطلع الطلب للتوصيل أول',
  'order.disputed': 'الطلب بيه بلاغ مفتوح، استنى قرار الإدارة',
  'courier.inactive': 'هالمندوب موقوف، اختار غيره',
  'courier.phone': 'رقم المندوب لازم يكون رقم عراقي صحيح (07xxxxxxxxx)',
  'courier.limit': 'وصلت الحد الأعلى للمناديب',
};

final _arabic = RegExp('[\u0600-\u06FF]');

/// Known code → our text; else the API's Arabic title (anti-leak etc.).
String pageOrderError(Object e, [String fallback = 'ما صار، جرّب مرة ثانية']) {
  if (e is! ApiException) return fallback;
  if (e.offline) return 'ماكو اتصال بالنت';
  final known = pageOrderErrorText[e.code];
  if (known != null) return known;
  final title = e.data['title'];
  if (title is String && _arabic.hasMatch(title)) return title;
  return switch (e.status) {
    404 => 'هالشي ما موجود أو مو إلك',
    409 => 'صار تغيير، حدّث وجرّب مرة ثانية',
    _ => fallback,
  };
}

final pageStoreOrdersRepoProvider = Provider<PageStoreOrdersRepo>(
  (ref) => PageStoreOrdersRepo(ref.watch(apiClientProvider)),
);
