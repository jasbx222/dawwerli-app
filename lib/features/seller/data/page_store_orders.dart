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
  }) async => PageStoreOrder.fromJson(
    await _api.post<Map<String, dynamic>>('$_base/$id/status', {
      'status': storeStatusApi(status),
      'reason': ?reason,
    }),
  );
}

final pageStoreOrdersRepoProvider = Provider<PageStoreOrdersRepo>(
  (ref) => PageStoreOrdersRepo(ref.watch(apiClientProvider)),
);
