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

String storeError(Object e) {
  if (e is ApiException) {
    return (e.data['title'] as String?) ??
        (e.data['detail'] as String?) ??
        storeGenericError;
  }
  return storeGenericError;
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
);

ProductCardData homeProductCard(HomeProduct p) => ProductCardData(
  id: p.id,
  pageId: p.pageId,
  name: p.name,
  description: p.description,
  price: p.price,
  image: p.image,
  available: p.available,
  stock: p.stock,
  caption: p.pageName,
  badge: p.pageRating > 0 ? p.pageRating.toStringAsFixed(1) : null,
  badgeIcon: AppIcon.star,
);

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
  const StoreProductCard({
    super.key,
    required this.data,
    this.cta = ProductCardCta.corner,
    this.width,
  });
  final ProductCardData data;
  final ProductCardCta cta;
  final double? width;

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
      cta: widget.cta,
      width: widget.width,
      adding: _adding,
      favorite: ref.watch(favoritesProvider).contains(d.id),
      onFavorite: () => ref.read(favoritesProvider.notifier).toggle(d.id),
      onTap: () => context.push(Routes.product(d.pageId, d.id)),
      onAdd: () => memberOnly(context, ref, _add),
    );
  }
}

/// Two columns on phones, three on wide screens. Rows size to their content,
/// so larger accessibility text never clips a card.
class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.items, this.skeleton = 0});
  final List<ProductCardData> items;

  /// When > 0, shows that many loading placeholders instead of [items].
  final int skeleton;

  static const gap = 12.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final cols = box.maxWidth >= 600 ? 3 : 2;
      final count = skeleton > 0 ? skeleton : items.length;
      final rows = <Widget>[];
      for (var r = 0; r * cols < count; r++) {
        if (r > 0) rows.add(const SizedBox(height: gap));
        rows.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < cols; c++) ...[
                if (c > 0) const SizedBox(width: gap),
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
        );
      }
      return Column(mainAxisSize: MainAxisSize.min, children: rows);
    },
  );
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
