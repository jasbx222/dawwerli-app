import 'package:dawwerli/core/api/api_client.dart';
import 'package:dawwerli/features/store/data/store_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers GET /api/v1/store/orders with what the API really returns.
class _Api implements ApiClient {
  _Api(this.body);
  final Object body;

  @override
  Future<T> get<T>(String path, {Map<String, Object?>? query}) async {
    expect(path, '/api/v1/store/orders');
    // Like Dio, a body that does not match T is a type error.
    return body as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _order(String id) => {
  'id': id,
  'no': 'S-1',
  'pageId': 'p1',
  'pageName': 'متجر',
  'status': 'new',
  'paymentMethod': 'cash',
  'paymentStatus': 'pending',
  'address': 'بغداد',
  'subtotal': 50000,
  'commission': 0,
  'items': [
    {'productId': 'x', 'name': 'قميص', 'unitPrice': 25000, 'quantity': 2},
  ],
  'createdAt': '2026-10-23T10:00:00Z',
  'statusChangedAt': '2026-10-23T10:00:00Z',
  'history': <Object>[],
  'kind': 'store',
};

Future<List<StoreOrder>> _read(Object body) async {
  final c = ProviderContainer(
    overrides: [apiClientProvider.overrideWithValue(_Api(body))],
  );
  addTearDown(c.dispose);
  return c.read(storeOrdersProvider.future);
}

void main() {
  test('reads the paged envelope the API returns', () async {
    final orders = await _read({
      'items': [_order('o1'), _order('o2')],
      'page': 1,
      'pageSize': 20,
      'total': 2,
    });
    expect(orders.map((o) => o.id), ['o1', 'o2']);
  });

  test('still reads a plain list', () async {
    final orders = await _read([_order('o1')]);
    expect(orders.single.id, 'o1');
  });
}
