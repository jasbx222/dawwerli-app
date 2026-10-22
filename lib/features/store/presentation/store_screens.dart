import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/loading_block.dart';
import '../../../core/widgets/pill.dart';
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
  });
  final String id;
  final String name;
  final String description;
  final int price;
  final List<String> images;
  final int stock;
  final bool available;

  factory StoreProduct.fromJson(Map<String, dynamic> j) => StoreProduct(
    id: j.s('id'),
    name: j.s('name'),
    description: j.s('description'),
    price: j.i('price'),
    images: ((j['imageUrls'] as List?) ?? const []).whereType<String>().where((u) => u.isNotEmpty).toList(),
    stock: j.i('stock'),
    available: j.b('available'),
  );
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
    items: [for (final i in j.l('items')) '${i.s('name')} × ${i.i('quantity')}'],
  );
}

final pageProductsProvider = FutureProvider.autoDispose.family<List<StoreProduct>, String>((ref, pageId) async {
  final list = asList(await ref.watch(apiClientProvider).get<List<dynamic>>('/api/v1/pages/$pageId/products'));
  return [for (final p in list) StoreProduct.fromJson(p)];
});

final productProvider = FutureProvider.autoDispose.family<StoreProduct, (String, String)>((ref, key) async {
  final j = await ref.watch(apiClientProvider).get<Map<String, dynamic>>('/api/v1/pages/${key.$1}/products/${key.$2}');
  return StoreProduct.fromJson(j);
});

final cartProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return await ref.watch(apiClientProvider).get<Map<String, dynamic>>('/api/v1/store/cart');
});

final storeOrderProvider = FutureProvider.autoDispose.family<StoreOrder, String>((ref, id) async {
  final j = await ref.watch(apiClientProvider).get<Map<String, dynamic>>('/api/v1/store/orders/$id');
  return StoreOrder.fromJson(j);
});

final storeOrdersProvider = FutureProvider.autoDispose<List<StoreOrder>>((ref) async {
  final list = asList(await ref.watch(apiClientProvider).get<List<dynamic>>('/api/v1/store/orders'));
  return [for (final o in list) StoreOrder.fromJson(o)];
});

/// Store orders of the signed-in page (GET /pages/me/store-orders).
final pageStoreOrdersProvider = FutureProvider.autoDispose<List<StoreOrder>>((ref) async {
  try {
    final j = await ref.watch(apiClientProvider).get<Map<String, dynamic>>(
      '/api/v1/pages/me/store-orders',
      query: {'page': 1, 'pageSize': 30},
    );
    return [for (final row in j.l('items')) StoreOrder.fromJson(row.m('order'))];
  } on ApiException {
    return const [];
  }
});

String _money(int n) => '$n د.ع';

class _StorePage extends StatelessWidget {
  const _StorePage({required this.title, required this.children, this.bottom});
  final String title;
  final List<Widget> children;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) => AppPage(
    title: title,
    bottom: bottom,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    ],
  );
}

String _status(String code) => switch (code) {
  'new' => 'جديد',
  'accepted' => 'مقبول',
  'out_for_delivery' => 'بالتوصيل',
  'delivered' => 'مستلم',
  'cancelled' => 'ملغي',
  'rejected' => 'مرفوض',
  'cash' => 'كاش عند الاستلام',
  'electronic' => 'دفع إلكتروني',
  _ => code,
};

String _err(Object e) {
  if (e is ApiException) return (e.data['title'] as String?) ?? (e.data['detail'] as String?) ?? 'صار خطأ، جرّب مرة ثانية';
  return 'صار خطأ، جرّب مرة ثانية';
}

class PageProductsScreen extends ConsumerWidget {
  const PageProductsScreen({super.key, required this.pageId});
  final String pageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(pageProductsProvider(pageId));
    return _StorePage(
      title: 'المنتجات',
      bottom: AppButton('السلة', onPressed: () => memberOnly(context, ref, () => context.push(Routes.cart))),
      children: [
        products.when(
          loading: () => const LoadingBlock(),
          error: (e, _) => Text(_err(e), style: AppText.body),
          data: (list) => list.isEmpty
              ? Text('ماكو منتجات بهالصفحة حالياً', style: AppText.body)
              : Column(
                  children: [
                    for (final p in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: p.images.isEmpty ? null : AppImage(p.images.first, width: 56, height: 56),
                            title: Text(p.name, style: AppText.strong),
                            subtitle: Text(p.available ? _money(p.price) : 'نفدت الكمية', style: AppText.body),
                            onTap: () => context.push(Routes.product(pageId, p.id)),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ProductGallery extends StatefulWidget {
  const _ProductGallery({required this.images});
  final List<String> images;

  @override
  State<_ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<_ProductGallery> {
  final _page = PageController();
  var _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 320,
            width: double.infinity,
            child: images.isEmpty
                ? ColoredBox(color: AppColors.blueTint)
                : PageView.builder(
                    controller: _page,
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (_, i) => AppImage(images[i], fit: BoxFit.cover),
                  ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () {
                  setState(() => _index = i);
                  _page.animateToPage(i, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                },
                child: Container(
                  width: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: i == _index ? AppColors.gold : AppColors.cardRing,
                      width: i == _index ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: AppImage(images[i], fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class ProductDetailsScreen extends ConsumerWidget {
  const ProductDetailsScreen({super.key, required this.pageId, required this.productId});
  final String pageId;
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productProvider((pageId, productId)));
    return product.when(
      loading: () => const _StorePage(title: '', children: [LoadingBlock()]),
      error: (e, _) => _StorePage(title: 'المنتج', children: [Text(_err(e))]),
      data: (p) => Scaffold(
        body: Column(
          children: [
            AppHeader(
              title: p.name,
              onBack: () => context.canPop() ? context.pop() : context.go(Routes.home),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _ProductGallery(images: p.images),
                  const SizedBox(height: 16),
                  Text(p.name, style: AppText.strong.copyWith(fontSize: 22)),
                  const SizedBox(height: 6),
                  Text(_money(p.price), style: AppText.number.copyWith(fontSize: 26, color: AppColors.gold)),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Pill(
                      p.available ? 'متوفر · ${p.stock} بالكمين' : 'نفدت الكمية',
                      bg: p.available ? AppColors.blueTint : AppColors.warnBg,
                      fg: p.available ? AppColors.blue : AppColors.warn,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppCard(
                    child: Text(
                      p.description.isEmpty ? 'بدون وصف' : p.description,
                      style: AppText.body.copyWith(height: 1.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    'بلّغ على المنتج',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => memberOnly(context, ref, () => _report(context, ref)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.viewPaddingOf(context).bottom),
              child: AppButton(
                p.available ? 'أضف للسلة' : 'نفدت الكمية',
                variant: p.available ? AppButtonVariant.primary : AppButtonVariant.disabled,
                onPressed: p.available ? () => memberOnly(context, ref, () => _add(context, ref, p.id)) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(apiClientProvider).post<Map<String, dynamic>>('/api/v1/store/cart/items', {'productId': id, 'quantity': 1});
      ref.invalidate(cartProvider);
      if (context.mounted) {
        showAppToast(context, 'انضاف للسلة');
        context.push(Routes.cart);
      }
    } on ApiException catch (e) {
      if (e.code == 'cart.other_page' && context.mounted) {
        final clear = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('السلة من صفحة ثانية'),
            content: const Text('تفرّغ السلة وتضيف هذا المنتج، لو تلغي؟'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('فرّغ السلة')),
            ],
          ),
        );
        if (clear == true) {
          await ref.read(apiClientProvider).delete<Map<String, dynamic>>('/api/v1/store/cart');
          await ref.read(apiClientProvider).post<Map<String, dynamic>>('/api/v1/store/cart/items', {'productId': id, 'quantity': 1});
          ref.invalidate(cartProvider);
          if (context.mounted) context.push(Routes.cart);
        }
      } else if (context.mounted) {
        showAppToast(context, _err(e));
      }
    }
  }

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final text = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('بلاغ على المنتج'),
        content: TextField(controller: text, maxLines: 3, decoration: const InputDecoration(hintText: 'شنو المشكلة؟')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('إرسال')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(apiClientProvider).post<Map<String, dynamic>>('/api/v1/reports', {
        'target': 'product',
        'targetId': productId,
        'reason': 'other',
        'text': text.text.trim().isEmpty ? 'بلاغ على منتج' : text.text.trim(),
      });
      if (context.mounted) showAppToast(context, 'وصل البلاغ');
    } catch (e) {
      if (context.mounted) showAppToast(context, _err(e));
    }
  }
}

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    return _StorePage(
      title: 'السلة',
      children: [
        cart.when(
          loading: () => const LoadingBlock(),
          error: (e, _) => Text(_err(e)),
          data: (j) {
            final items = j.l('items');
            if (items.isEmpty) return Text('السلة فارغة', style: AppText.body);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(j.s('pageName'), style: AppText.strong),
                const SizedBox(height: 8),
                for (final i in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(child: Text('${i.s('name')} × ${i.i('quantity')} · ${_money(i.i('price'))}', style: AppText.body)),
                  ),
                Text('المجموع ${_money(j.i('subtotal'))}', style: AppText.strong),
                const SizedBox(height: 16),
                AppButton('كمّل الطلب', onPressed: () => context.push(Routes.checkout)),
                const SizedBox(height: 8),
                AppButton('فرّغ السلة', variant: AppButtonVariant.ghost, onPressed: () async {
                  await ref.read(apiClientProvider).delete<Map<String, dynamic>>('/api/v1/store/cart');
                  ref.invalidate(cartProvider);
                }),
              ],
            );
          },
        ),
      ],
    );
  }
}

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _address = TextEditingController();
  String _pay = 'cash';
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_address.text.trim().isEmpty) {
      setState(() => _error = 'اكتب العنوان');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final j = await ref.read(apiClientProvider).post<Map<String, dynamic>>('/api/v1/store/orders', {
        'address': _address.text.trim(),
        'paymentMethod': _pay,
      });
      ref.invalidate(cartProvider);
      ref.invalidate(storeOrdersProvider);
      ref.invalidate(storeOrderProvider);
      if (mounted) context.go(Routes.storeOrder(j.s('id')));
    } catch (e) {
      setState(() => _error = _err(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _StorePage(
      title: 'إكمال الطلب',
      bottom: AppButton(_busy ? '...' : 'تأكيد الطلب', onPressed: _busy ? null : _submit),
      children: [
        TextField(controller: _address, decoration: const InputDecoration(labelText: 'العنوان'), maxLength: 300),
        const SizedBox(height: 12),
        RadioGroup<String>(
          groupValue: _pay,
          onChanged: (v) => setState(() => _pay = v ?? _pay),
          child: Column(
            children: const [
              RadioListTile<String>(value: 'cash', title: Text('كاش عند الاستلام')),
              RadioListTile<String>(value: 'electronic', title: Text('دفع إلكتروني')),
            ],
          ),
        ),
        if (_error != null) Text(_error!, style: AppText.body.copyWith(color: AppColors.danger)),
      ],
    );
  }
}

class StoreOrdersScreen extends ConsumerWidget {
  const StoreOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(storeOrdersProvider);
    return _StorePage(
      title: 'طلبات المتجر',
      children: [
        orders.when(
          loading: () => const LoadingBlock(),
          error: (e, _) => Text(_err(e)),
          data: (list) => list.isEmpty
              ? Text('ماكو طلبات متجر', style: AppText.body)
              : Column(
                  children: [
                    for (final o in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${o.no} · ${o.pageName}', style: AppText.strong),
                            subtitle: Text('${_status(o.status)} · ${_money(o.subtotal)}', style: AppText.body),
                            onTap: () => context.push(Routes.storeOrder(o.id)),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class StoreOrderScreen extends ConsumerWidget {
  const StoreOrderScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(storeOrderProvider(id));
    return order.when(
      loading: () => const _StorePage(title: 'الطلب', children: [LoadingBlock()]),
      error: (e, _) => _StorePage(title: 'الطلب', children: [Text(_err(e))]),
      data: (current) => _StorePage(
        title: current.no,
        bottom: current.status == 'new'
            ? AppButton('إلغاء الطلب', variant: AppButtonVariant.danger, onPressed: () async {
                try {
                  await ref.read(apiClientProvider).post<Map<String, dynamic>>('/api/v1/store/orders/$id/cancel');
                  ref.invalidate(storeOrderProvider(id));
                  ref.invalidate(storeOrdersProvider);
                } catch (e) {
                  if (context.mounted) showAppToast(context, _err(e));
                }
              })
            : null,
        children: [
          Text(current.pageName, style: AppText.strong),
          const SizedBox(height: 8),
          Text('الحالة: ${_status(current.status)}', style: AppText.body),
          Text('الدفع: ${_status(current.payment)}', style: AppText.body),
          Text(current.address, style: AppText.body),
          const SizedBox(height: 8),
          for (final line in current.items) Text(line, style: AppText.body),
          const SizedBox(height: 8),
          Text('المجموع ${_money(current.subtotal)}', style: AppText.strong),
        ],
      ),
    );
  }
}
