import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/prefs.dart';
import '../../../core/utils/format.dart';
import '../../guest/guest.dart';

class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.images,
    required this.stock,
    required this.available,
    this.category = '',
  });
  final String id;
  final String name;
  final String description;
  final int price;
  final List<String> images;
  final int stock;
  final bool available;
  final String category;

  String get image => images.isEmpty ? '' : images.first;

  /// Few left: worth telling the customer before they decide.
  bool get lowStock => available && stock > 0 && stock <= 3;

  factory StoreProduct.fromJson(Map<String, dynamic> j) {
    final urls = ((j['imageUrls'] as List?) ?? const [])
        .whereType<String>()
        .where((u) => u.isNotEmpty)
        .toList();
    final single = j.os('imageUrl');
    final stock = j.i('stock');
    return StoreProduct(
      id: j.s('id'),
      name: j.s('name'),
      description: j.s('description'),
      price: j.i('price'),
      images: urls.isEmpty && single != null && single.isNotEmpty
          ? [single]
          : urls,
      stock: stock,
      available: j.containsKey('available') ? j.b('available') : stock > 0,
      category: j.s('category'),
    );
  }
}

class StoreOrder {
  const StoreOrder({
    required this.id,
    required this.no,
    required this.pageName,
    required this.status,
    required this.payment,
    required this.address,
    required this.subtotal,
    required this.items,
  });
  final String id;
  final String no;
  final String pageName;
  final String status;
  final String payment;
  final String address;
  final int subtotal;
  final List<String> items;

  factory StoreOrder.fromJson(Map<String, dynamic> j) => StoreOrder(
    id: j.s('id'),
    no: j.s('no'),
    pageName: j.s('pageName'),
    status: j.s('status'),
    payment: j.s('paymentMethod'),
    address: j.s('address'),
    subtotal: j.i('subtotal'),
    items: [
      for (final i in j.l('items')) '${i.s('name')} × ${i.i('quantity')}',
    ],
  );
}

/// One line of the one-page cart.
class CartLine {
  const CartLine({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.stock,
    required this.image,
  });
  final String productId;
  final String name;
  final int price;
  final int quantity;
  final int stock;
  final String image;

  factory CartLine.fromJson(Map<String, dynamic> j) => CartLine(
    productId: j.s('productId'),
    name: j.s('name'),
    price: j.containsKey('price') ? j.i('price') : j.i('unitPrice'),
    quantity: j.i('quantity'),
    stock: j.i('stock'),
    image: j.os('imageUrl') ?? '',
  );
}

class Cart {
  const Cart({
    required this.pageId,
    required this.pageName,
    required this.lines,
    required this.subtotal,
  });
  final String pageId;
  final String pageName;
  final List<CartLine> lines;
  final int subtotal;

  static const empty = Cart(pageId: '', pageName: '', lines: [], subtotal: 0);

  bool get isEmpty => lines.isEmpty;
  int get count => lines.fold(0, (n, l) => n + l.quantity);

  factory Cart.fromJson(Map<String, dynamic> j) => Cart(
    pageId: j.s('pageId'),
    pageName: j.s('pageName'),
    lines: [for (final l in j.l('items')) CartLine.fromJson(l)],
    subtotal: j.i('subtotal'),
  );
}

final pageProductsProvider = FutureProvider.autoDispose
    .family<List<StoreProduct>, String>((ref, pageId) async {
      final raw = await ref
          .watch(apiClientProvider)
          .get<Object?>('/api/v1/pages/$pageId/products');
      // Plain list, or a paged envelope `{items: [...]}`.
      final list = raw is Map ? asList(raw['items']) : asList(raw);
      final products = [for (final p in list) StoreProduct.fromJson(p)];
      // In-stock first; keep the server order inside each group.
      return [
        ...products.where((p) => p.available),
        ...products.where((p) => !p.available),
      ];
    });

final productProvider = FutureProvider.autoDispose
    .family<StoreProduct, (String, String)>((ref, key) async {
      final j = await ref
          .watch(apiClientProvider)
          .get<Map<String, dynamic>>(
            '/api/v1/pages/${key.$1}/products/${key.$2}',
          );
      return StoreProduct.fromJson(j);
    });

final cartProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  return await ref
      .watch(apiClientProvider)
      .get<Map<String, dynamic>>('/api/v1/store/cart');
});

/// Parsed cart for badges and the floating cart bar. Guests have no cart.
final cartSummaryProvider = Provider.autoDispose<Cart>((ref) {
  if (ref.watch(guestProvider)) return Cart.empty;
  final j = ref.watch(cartProvider).value;
  return j == null ? Cart.empty : Cart.fromJson(j);
});

final storeOrderProvider = FutureProvider.autoDispose
    .family<StoreOrder, String>((ref, id) async {
      final j = await ref
          .watch(apiClientProvider)
          .get<Map<String, dynamic>>('/api/v1/store/orders/$id');
      return StoreOrder.fromJson(j);
    });

final storeOrdersProvider = FutureProvider.autoDispose<List<StoreOrder>>((
  ref,
) async {
  final list = asList(
    await ref
        .watch(apiClientProvider)
        .get<List<dynamic>>('/api/v1/store/orders'),
  );
  return [for (final o in list) StoreOrder.fromJson(o)];
});

/// Store orders of the signed-in page (GET /pages/me/store-orders).
final pageStoreOrdersProvider = FutureProvider.autoDispose<List<StoreOrder>>((
  ref,
) async {
  try {
    final j = await ref
        .watch(apiClientProvider)
        .get<Map<String, dynamic>>(
          '/api/v1/pages/me/store-orders',
          query: {'page': 1, 'pageSize': 30},
        );
    return [
      for (final row in j.l('items')) StoreOrder.fromJson(row.m('order')),
    ];
  } on ApiException {
    return const [];
  }
});

/// Products the customer hearted. Kept on the device.
final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);

class FavoritesNotifier extends Notifier<Set<String>> {
  static const _key = 'store.favorites';

  @override
  Set<String> build() => {
    ...?ref.watch(sharedPrefsProvider).getStringList(_key),
  };

  bool toggle(String productId) {
    final next = {...state};
    final added = next.add(productId);
    if (!added) next.remove(productId);
    state = next;
    ref.read(sharedPrefsProvider).setStringList(_key, next.toList());
    return added;
  }
}

/// «35000» → «35,000 د.ع»
String storePrice(int amount) => '${thousands(amount)} د.ع';
