import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/notes.dart';
import '../../../guest/guest.dart';
import '../../../home/domain/home_models.dart';
import '../../data/store_data.dart';
import 'product_card.dart';

const storeGenericError = 'صار خطأ، جرّب مرة ثانية';

/// Arabic text for the store API's error codes. English API titles are never
/// shown to customers.
const storeErrorText = <String, String>{
  'cart.other_page': 'سلتك بيها منتجات من صفحة ثانية',
  'cart.empty': 'سلتك فارغة',
  'cart.quantity': 'الكمية مو صحيحة',
  'product.stock': 'الكمية المطلوبة مو متوفرة هسه',
  'product.unavailable': 'هالمنتج مو متاح هسه',
  'product.not_found': 'هالمنتج ما بقى موجود',
  'page.unavailable': 'الصفحة متوقفة عن البيع هسه',
  'page.suspended': 'الصفحة موقوفة هسه',
  'page.not_verified': 'الصفحة بعدها ما توثّقت',
  'payment.not_configured':
      'الدفع الإلكتروني مو متوفر بعد، اختار الكاش عند الاستلام',
  'store_order.transition': 'حالة الطلب تغيّرت، حدّث الصفحة',
  'store_order.not_found': 'ما لكينا هالطلب',
  'account.banned': 'حسابك موقوف، تواصل ويانا',
  'report.duplicate': 'بلّغت عن هذا قبل، فريقنا يراجعه',
  'rating.not_received': 'تكدر تقيّم بس المنتجات اللي استلمتها',
  'rating.prohibited': 'التعليق بي كلمات ممنوعة',
  'rating.stars': 'اختار من نجمة لخمس نجوم',
  'rating.comment': 'التعليق طويل',
  'seller.session_expired': 'انتهت الجلسة، سجّل دخول مرة ثانية',
};

String storeError(Object e) {
  if (e is! ApiException) return storeGenericError;
  if (e.offline) return 'ماكو اتصال بالنت';
  final known = storeErrorText[e.code];
  if (known != null) return known;
  return switch (e.status) {
    401 => 'سجّل دخول حتى تكمل',
    403 => 'ما مسموح تسوي هالشي',
    404 => 'الشي اللي تدوره ما موجود',
    409 => 'صار تغيير، حدّث الصفحة وجرّب مرة ثانية',
    429 => 'محاولات كثيرة، استنى شوية وجرّب',
    400 || 422 => 'تأكد من المعلومات وجرّب مرة ثانية',
    _ => storeGenericError,
  };
}

ProductCardData cardOf(StoreProduct p, String pageId) => ProductCardData(
  id: p.id,
  pageId: pageId,
  name: p.name,
  description: p.description,
  price: p.price,
  image: p.image,
  available: p.available,
  stock: p.stock,
  badge: p.lowStock ? 'باقي ${p.stock}' : null,
  rating: p.rating,
  ratingCount: p.ratingCount,
);

ProductCardData homeProductCard(HomeProduct p, {String? badge}) =>
    ProductCardData(
      id: p.id,
      pageId: p.pageId,
      name: p.name,
      description: p.description,
      price: p.price,
      image: p.image,
      available: p.available,
      stock: p.stock,
      caption: p.pageName,
      badge:
          badge ??
          (p.stock != null && p.stock! > 0 && p.stock! <= 3
              ? 'باقي ${p.stock}'
              : null),
      rating: p.rating,
      ratingCount: p.ratingCount,
    );

/// Hearts or un-hearts a product (members only). Failures roll back and toast.
void toggleFavorite(
  BuildContext context,
  WidgetRef ref,
  String productId,
  String pageId,
) => memberOnly(context, ref, () async {
  try {
    final added = await ref
        .read(favoritesProvider.notifier)
        .toggle(productId, pageId: pageId);
    if (context.mounted) {
      showAppToast(
        context,
        added ? 'انضاف للمفضلة' : 'انشال من المفضلة',
        icon: added ? AppIcon.heartFilled : AppIcon.heart,
      );
    }
  } catch (e) {
    if (context.mounted) {
      showAppToast(context, storeError(e), icon: AppIcon.alert);
    }
  }
});

/// Adds [productId] to the one-page cart. When the cart holds another page's
/// products the customer chooses: empty it and add, or cancel.
/// Returns true when the product ended up in the cart.
Future<bool> addToCart(
  BuildContext context,
  WidgetRef ref,
  String productId, {
  int quantity = 1,
}) async {
  final api = ref.read(apiClientProvider);
  Future<void> add() => api.post<Map<String, dynamic>>(
    '/api/v1/store/cart/items',
    {'productId': productId, 'quantity': quantity},
  );
  try {
    await add();
    ref.invalidate(cartProvider);
    return true;
  } on ApiException catch (e) {
    if (!context.mounted) return false;
    if (e.code != 'cart.other_page') {
      showAppToast(context, storeError(e), icon: AppIcon.alert);
      return false;
    }
    final pageName = ref.read(cartSummaryProvider).pageName;
    final clear = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => OtherPageCartSheet(pageName: pageName),
    );
    if (clear != true) return false;
    try {
      await api.delete<Object?>('/api/v1/store/cart');
      await add();
      ref.invalidate(cartProvider);
      return true;
    } catch (e) {
      if (context.mounted) {
        showAppToast(context, storeError(e), icon: AppIcon.alert);
      }
      return false;
    }
  }
}

/// «السلة من صفحة ثانية»: empty it and add, or cancel.
class OtherPageCartSheet extends StatelessWidget {
  const OtherPageCartSheet({super.key, this.pageName = ''});
  final String pageName;

  @override
  Widget build(BuildContext context) => AppSheet(
    children: [
      Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.warnBg,
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: const AppSvgIcon(AppIcon.cart, color: AppColors.warn),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'سلتك بيها منتجات من صفحة ثانية',
        textAlign: TextAlign.center,
        style: AppText.big.copyWith(fontSize: 18),
      ),
      const SizedBox(height: 6),
      Text(
        pageName.isEmpty
            ? 'السلة تكون من صفحة وحدة. تفرّغها وتضيف هالمنتج؟'
            : 'السلة بيها منتجات من «$pageName»، والسلة تكون من صفحة وحدة. تفرّغها وتضيف هالمنتج؟',
        textAlign: TextAlign.center,
        style: AppText.muted.copyWith(fontSize: 14, height: 1.7),
      ),
      const SizedBox(height: 18),
      AppButton(
        'فرّغ السلة وأضف',
        onPressed: () => Navigator.of(context).pop(true),
      ),
      const SizedBox(height: 10),
      AppButton(
        'إلغاء',
        variant: AppButtonVariant.ghost,
        onPressed: () => Navigator.of(context).pop(false),
      ),
    ],
  );
}

/// [ProductCard] wired to favorites, quick add-to-cart and the details screen.
class StoreProductCard extends ConsumerStatefulWidget {
  const StoreProductCard({super.key, required this.data});
  final ProductCardData data;

  @override
  ConsumerState<StoreProductCard> createState() => _StoreProductCardState();
}

class _StoreProductCardState extends ConsumerState<StoreProductCard> {
  bool _adding = false;

  Future<void> _add() async {
    setState(() => _adding = true);
    final ok = await addToCart(context, ref, widget.data.id);
    if (!mounted) return;
    setState(() => _adding = false);
    if (ok) showAppToast(context, 'انضاف «${widget.data.name}» للسلة');
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return ProductCard(
      data: d,
      adding: _adding,
      favorite: ref.watch(favoritesProvider).contains(d.id),
      onFavorite: () => toggleFavorite(context, ref, d.id, d.pageId),
      onTap: () => context.push(Routes.product(d.pageId, d.id)),
      onAdd: () => memberOnly(context, ref, _add),
    );
  }
}

/// Products in equal-width columns: 2 on phones, 3 on tablets, 4 on wide
/// screens (a column is at least [minCard] wide). Each row takes the height
/// of its tallest card, and cards stretch to it, so a row always lines up.
class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.items, this.skeleton = 0});
  final List<ProductCardData> items;

  /// When > 0, shows that many loading placeholders instead of [items].
  final int skeleton;

  static const minCard = 200.0;

  static int columnsFor(double width) =>
      ((width + 16) / (minCard + 16)).floor().clamp(2, 4);

  static double gapFor(double width) => width >= 700 ? 18 : 12;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final cols = columnsFor(box.maxWidth);
      final gap = gapFor(box.maxWidth);
      final count = skeleton > 0 ? skeleton : items.length;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r * cols < count; r++)
            Padding(
              padding: EdgeInsets.only(top: r == 0 ? 0 : gap),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < cols; c++) ...[
                      if (c > 0) SizedBox(width: gap),
                      Expanded(
                        child: r * cols + c >= count
                            ? const SizedBox.shrink()
                            : skeleton > 0
                            ? const ProductCardSkeleton()
                            : StoreProductCard(data: items[r * cols + c]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

/// Centers store content with a readable max width and screen-edge padding
/// that grows on tablets and the web.
class StoreWidth extends StatelessWidget {
  const StoreWidth({
    super.key,
    required this.child,
    this.maxWidth = 1120,
    this.top = 16,
    this.padded = true,
  });
  final Widget child;
  final double maxWidth;
  final double top;

  /// Adds the horizontal screen padding (16, or 24 from 700px).
  final bool padded;

  static double sideFor(double width) => width >= 700 ? 24 : 16;

  @override
  Widget build(BuildContext context) {
    final side = padded ? sideFor(MediaQuery.sizeOf(context).width) : 0.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(side, top, side, 0),
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

/// Empty / error block for store lists, with an optional retry.
class StoreMessage extends StatelessWidget {
  const StoreMessage({
    super.key,
    required this.title,
    required this.body,
    this.icon = AppIcon.bag,
    this.onRetry,
  });
  final String title;
  final String body;
  final AppIcon icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyStateCard(
    icon: icon,
    title: title,
    body: body,
    action: onRetry == null
        ? null
        : AppButton(
            'جرّب مرة ثانية',
            icon: AppIcon.refresh,
            compact: true,
            variant: AppButtonVariant.ghost,
            onPressed: onRetry,
          ),
  );
}

/// Floating navy bar: item count, subtotal and «عرض السلة».
class CartBar extends StatelessWidget {
  const CartBar({super.key, required this.cart, required this.onTap});
  final Cart cart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'السلة، ${cart.count} قطعة، ${storePrice(cart.subtotal)}',
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 16, 10),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: .25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const AppSvgIcon(
                AppIcon.cart,
                size: 20,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${cart.count} قطعة بالسلة',
                    style: AppText.label.copyWith(color: AppColors.white),
                  ),
                  Text(
                    storePrice(cart.subtotal),
                    style: AppText.number.copyWith(
                      color: AppColors.goldSoft,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'عرض السلة',
              style: AppText.label.copyWith(
                color: AppColors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            const AppSvgIcon(
              AppIcon.chevronLeft,
              size: 18,
              color: AppColors.white,
            ),
          ],
        ),
      ),
    ),
  );
}
