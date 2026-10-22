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
    this.rating = 0,
    this.ratingCount = 0,
  });
  final String id;
  final String name;
  final String description;
  final int price;
  final List<String> images;
  final int stock;
  final bool available;
  final String category;

  /// Average product rating (0 when nobody rated it yet) and how many ratings.
  final double rating;
  final int ratingCount;

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
      rating: j.d('rating'),
      ratingCount: j.i('ratingCount'),
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
    this.lines = const [],
    this.pageId = '',
  });
  final String id;
  final String no;
  final String pageName;
  final String status;
  final String payment;
  final String address;
  final int subtotal;
  final List<String> items;
  final List<StoreOrderLine> lines;
  final String pageId;

  bool get delivered => status == 'delivered';

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
    pageId: j.s('pageId'),
    lines: [
      for (final i in j.l('items'))
        StoreOrderLine(
          productId: i.s('productId'),
          name: i.s('name'),
          quantity: i.i('quantity'),
          image: i.os('imageUrl') ?? '',
        ),
    ],
  );
}

class StoreOrderLine {
  const StoreOrderLine({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.image,
  });
  final String productId;
  final String name;
  final int quantity;
  final String image;
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

/// A product in «المفضلة».
class FavoriteProduct {
  const FavoriteProduct({
    required this.pageId,
    required this.product,
    this.pageName = '',
  });
  final String pageId;
  final String pageName;
  final StoreProduct product;
}

/// True when the server answered 404 because the route itself is missing
/// (an API build without the endpoint), not because a record was not found.
bool missingEndpoint(Object e) =>
    e is ApiException &&
    e.status == 404 &&
    (e.code == 'http_404' || e.code == 'error');

/// Hearted product ids of the signed-in customer, synced with
/// GET/PUT/DELETE /api/v1/favorites. The last known set is cached on the device
/// (with each product's page) so hearts show instantly and still work against
/// API builds that have no favorites endpoints yet.
final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);

class FavoritesNotifier extends Notifier<Set<String>> {
  static const _key = 'store.favorites.v2';

  /// productId → pageId, needed to open or reload a favorite.
  final Map<String, String> pages = {};
  bool _serverless = false;

  @override
  Set<String> build() {
    pages.clear();
    for (final e
        in ref.watch(sharedPrefsProvider).getStringList(_key) ??
            const <String>[]) {
      final parts = e.split('|');
      pages[parts.first] = parts.length > 1 ? parts[1] : '';
    }
    // Guests have no favorites; the cache waits for the next sign-in sync.
    if (ref.watch(guestProvider)) return const {};
    Future.microtask(sync);
    return pages.keys.toSet();
  }

  /// Replaces the set with the server's list.
  Future<void> sync() async {
    try {
      final list = await ref
          .read(apiClientProvider)
          .get<List<dynamic>>('/api/v1/favorites');
      pages
        ..clear()
        ..addEntries([
          for (final f in asList(list)) MapEntry(f.s('id'), f.s('pageId')),
        ]);
      _serverless = false;
      _save();
      state = pages.keys.toSet();
    } catch (e) {
      if (missingEndpoint(e)) _serverless = true;
    }
  }

  /// Optimistic toggle; rolls back when the server refuses.
  Future<bool> toggle(String productId, {String pageId = ''}) async {
    final adding = !state.contains(productId);
    void apply(bool add) {
      if (add) {
        pages[productId] = pageId.isNotEmpty
            ? pageId
            : (pages[productId] ?? '');
      } else {
        pages.remove(productId);
      }
      _save();
      state = pages.keys.toSet();
    }

    apply(adding);
    if (_serverless) return adding;
    final api = ref.read(apiClientProvider);
    try {
      if (adding) {
        await api.put<Object?>('/api/v1/products/$productId/favorite');
      } else {
        await api.delete<Object?>('/api/v1/products/$productId/favorite');
      }
    } catch (e) {
      if (missingEndpoint(e)) {
        _serverless = true;
      } else {
        apply(!adding);
        rethrow;
      }
    }
    return adding;
  }

  void _save() => ref.read(sharedPrefsProvider).setStringList(_key, [
    for (final e in pages.entries) '${e.key}|${e.value}',
  ]);
}

/// «المفضلة» list. Server list when available; otherwise each cached favorite
/// is loaded from its page. Hidden products come back as unavailable.
final favoriteProductsProvider =
    FutureProvider.autoDispose<List<FavoriteProduct>>((ref) async {
      final ids = ref.watch(favoritesProvider);
      final api = ref.watch(apiClientProvider);
      try {
        final list = asList(await api.get<List<dynamic>>('/api/v1/favorites'));
        return [
          for (final f in list)
            FavoriteProduct(
              pageId: f.s('pageId'),
              pageName: f.s('pageName'),
              product: StoreProduct.fromJson(f),
            ),
        ];
      } catch (e) {
        if (!missingEndpoint(e)) rethrow;
      }
      final pages = ref.read(favoritesProvider.notifier).pages;
      final out = await Future.wait([
        for (final id in ids)
          if ((pages[id] ?? '').isNotEmpty)
            api
                .get<Map<String, dynamic>>(
                  '/api/v1/pages/${pages[id]}/products/$id',
                )
                .then<FavoriteProduct?>(
                  (j) => FavoriteProduct(
                    pageId: pages[id]!,
                    product: StoreProduct.fromJson(j),
                  ),
                )
                .catchError((Object _) => null),
      ]);
      return out.whereType<FavoriteProduct>().toList();
    });

class ProductReview {
  const ProductReview({
    required this.name,
    required this.stars,
    required this.comment,
    required this.at,
  });
  final String name;
  final int stars;
  final String comment;
  final DateTime? at;

  factory ProductReview.fromJson(Map<String, dynamic> j) => ProductReview(
    name: j.s('customerName'),
    stars: j.i('stars'),
    comment: j.s('comment'),
    at: j.ot('updatedAt'),
  );
}

/// Latest reviews of a product. Empty on API builds without ratings.
final productReviewsProvider = FutureProvider.autoDispose
    .family<List<ProductReview>, String>((ref, productId) async {
      try {
        final j = await ref
            .watch(apiClientProvider)
            .get<Map<String, dynamic>>(
              '/api/v1/products/$productId/ratings',
              query: {'pageSize': 10},
            );
        return [for (final r in j.l('items')) ProductReview.fromJson(r)];
      } catch (e) {
        if (missingEndpoint(e)) return const [];
        rethrow;
      }
    });

/// Whether the signed-in customer received this product (so can rate it), and their rating.
class MyRating {
  const MyRating({required this.canRate, this.stars, this.comment = ''});
  final bool canRate;
  final int? stars;
  final String comment;

  static const none = MyRating(canRate: false);
}

final myRatingProvider = FutureProvider.autoDispose.family<MyRating, String>((
  ref,
  productId,
) async {
  if (ref.watch(guestProvider)) return MyRating.none;
  try {
    final j = await ref
        .watch(apiClientProvider)
        .get<Map<String, dynamic>>('/api/v1/products/$productId/ratings/mine');
    return MyRating(
      canRate: j.b('canRate'),
      stars: j.oi('stars'),
      comment: j.s('comment'),
    );
  } catch (_) {
    return MyRating.none;
  }
});

/// «35000» → «35,000 د.ع»
String storePrice(int amount) => '${thousands(amount)} د.ع';
