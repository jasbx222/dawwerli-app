import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/api/api_client.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_inputs.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/loading_block.dart';
import '../../../core/widgets/order_map.dart';
import '../../../core/widgets/page_tile.dart';
import '../../../core/widgets/radio_row.dart';
import '../../guest/guest.dart';
import '../../home/data/home_providers.dart';
import '../../more/more_data.dart';
import '../../post/domain/request_draft.dart' show PostRules;
import '../data/store_data.dart';
import 'page_search.dart';
import 'widgets/product_card.dart';
import 'widgets/product_reviews.dart';
import 'widgets/store_widgets.dart';
import '../../wall/wall_math.dart';
import '../../wall/wall_preview_screen.dart';

export '../data/store_data.dart';
export 'store_order_screens.dart';

String _money(int n) => storePrice(n);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ],
  );
}

String _err(Object e) => storeError(e);

// ───────────────────────── Products of a page ─────────────────────────

/// Full-screen products list of one page (`/pages/p/:id/products`).
class PageProductsScreen extends ConsumerWidget {
  const PageProductsScreen({super.key, required this.pageId});
  final String pageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(pageProfileProvider(pageId)).value;
    final cart = ref.watch(cartSummaryProvider);
    return AppPage(
      title: 'المنتجات',
      subtitle: page?.name,
      bottom: cart.isEmpty
          ? null
          : StoreWidth(
              top: 0,
              padded: false,
              maxWidth: 760,
              child: CartBar(
                cart: cart,
                onTap: () => context.push(Routes.cart),
              ),
            ),
      endDrawer: PageFilterDrawer(pageId: pageId),
      onNearEnd: () => loadMorePageProducts(ref, pageId),
      onRefresh: () async => refreshPageProducts(ref, pageId),
      children: [StoreWidth(child: PageProductsSection(pageId: pageId))],
    );
  }
}

/// «منتجات أعلى الصفحات تقييماً» → «الكل».
class TopProductsScreen extends ConsumerWidget {
  const TopProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(topRatedProductsProvider);
    final cart = ref.watch(cartSummaryProvider);
    return AppPage(
      title: 'منتجات أعلى الصفحات تقييماً',
      subtitle: 'من الصفحات اللي زباينها راضين عنها',
      bottom: cart.isEmpty
          ? null
          : StoreWidth(
              top: 0,
              padded: false,
              maxWidth: 760,
              child: CartBar(
                cart: cart,
                onTap: () => context.push(Routes.cart),
              ),
            ),
      children: [
        StoreWidth(
          child: products.when(
            loading: () => const ProductGrid(items: [], skeleton: 6),
            error: (e, _) => StoreMessage(
              icon: AppIcon.wifiOff,
              title: 'ما قدرنا نجيب المنتجات',
              body: 'تأكد من النت وجرّب مرة ثانية.',
              onRetry: () => ref.invalidate(topRatedProductsProvider),
            ),
            data: (list) => list.isEmpty
                ? const StoreMessage(
                    title: 'ماكو منتجات حالياً',
                    body: 'أول ما الصفحات تضيف منتجات راح تشوفها هنا.',
                  )
                : ProductGrid(
                    items: [for (final p in list) homeProductCard(p)],
                  ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Product details ─────────────────────────

class _Gallery extends StatefulWidget {
  const _Gallery({
    required this.images,
    required this.favorite,
    required this.onFavorite,
    required this.soldOut,
    required this.height,
    this.rounded = false,
  });
  final List<String> images;
  final bool favorite;
  final VoidCallback onFavorite;
  final bool soldOut;
  final double height;

  /// Rounded on all corners inside a centered column (tablet / web); else
  /// full-bleed under the status bar with a rounded bottom.
  final bool rounded;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _page = PageController();
  var _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _go(int i) {
    setState(() => _index = i);
    _page.animateToPage(
      i,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final top = widget.rounded ? 0.0 : MediaQuery.viewPaddingOf(context).top;
    final height = widget.height;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: ClipRRect(
            borderRadius: widget.rounded
                ? BorderRadius.circular(28)
                : const BorderRadius.vertical(bottom: Radius.circular(32)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: AppColors.blueTint,
                  child: images.isEmpty
                      ? Center(
                          child: AppSvgIcon(
                            AppIcon.bag,
                            size: 72,
                            color: AppColors.blue.withValues(alpha: .3),
                          ),
                        )
                      : PageView.builder(
                          controller: _page,
                          itemCount: images.length,
                          onPageChanged: (i) => setState(() => _index = i),
                          itemBuilder: (_, i) =>
                              AppImage(images[i], fit: BoxFit.cover),
                        ),
                ),
                if (widget.soldOut)
                  IgnorePointer(
                    child: ColoredBox(
                      color: AppColors.navy.withValues(alpha: .35),
                    ),
                  ),
                PositionedDirectional(
                  top: top + 10,
                  start: 14,
                  child: _RoundButton(
                    icon: AppIcon.back,
                    label: 'رجوع',
                    onTap: () => popOr(context),
                  ),
                ),
                PositionedDirectional(
                  top: top + 10,
                  end: 14,
                  child: FavoriteButton(
                    on: widget.favorite,
                    onTap: widget.onFavorite,
                    size: 42,
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    bottom: 14,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.navy.withValues(alpha: .45),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < images.length; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: i == _index ? 16 : 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: i == _index
                                      ? AppColors.gold
                                      : AppColors.white.withValues(alpha: .7),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (images.length > 1)
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.fromLTRB(
                widget.rounded ? 0 : 16,
                12,
                widget.rounded ? 0 : 16,
                0,
              ),
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => Semantics(
                button: true,
                selected: i == _index,
                label: 'صورة ${i + 1} من ${images.length}',
                child: GestureDetector(
                  onTap: () => _go(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: i == _index
                            ? AppColors.gold
                            : AppColors.cardRing,
                        width: i == _index ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AppImage(images[i], fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final AppIcon icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: AppSvgIcon(icon, size: 20, color: AppColors.ink),
      ),
    ),
  );
}

/// − qty + stepper, bounded by stock and the cart maximum.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.max,
    required this.onChanged,
  });
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget step(AppIcon icon, String label, bool enabled, int next) =>
        Semantics(
          button: true,
          enabled: enabled,
          label: label,
          child: GestureDetector(
            onTap: enabled ? () => onChanged(next) : null,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: enabled ? AppColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppSvgIcon(
                icon,
                size: 18,
                color: enabled ? AppColors.ink : AppColors.checkOff,
              ),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.tabTrack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          step(AppIcon.plus, 'زيد الكمية', value < max, value + 1),
          SizedBox(
            width: 34,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AppText.number.copyWith(
                fontSize: 17,
                color: AppColors.ink,
              ),
            ),
          ),
          step(AppIcon.minus, 'نقّص الكمية', value > 1, value - 1),
        ],
      ),
    );
  }
}

class ProductDetailsScreen extends ConsumerStatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.pageId,
    required this.productId,
  });
  final String pageId;
  final String productId;

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  /// Server cap per cart line (Store:MaxCartQuantity).
  static const _maxPerLine = 20;
  var _qty = 1;
  var _adding = false;

  (String, String) get _key => (widget.pageId, widget.productId);

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(productProvider(_key));
    return product.when(
      loading: () => const _DetailsSkeleton(),
      error: (e, _) => AppPage(
        title: 'المنتج',
        children: [
          StoreWidth(
            maxWidth: 760,
            child: e is ApiException && e.status == 404
                ? StoreMessage(
                    title: 'هالمنتج ما بقى متوفر',
                    body: 'يمكن الصفحة شالته أو خفته. شوف باقي منتجاتها.',
                    onRetry: null,
                  )
                : StoreMessage(
                    icon: AppIcon.wifiOff,
                    title: 'ما قدرنا نفتح المنتج',
                    body: 'تأكد من النت وجرّب مرة ثانية.',
                    onRetry: () => ref.invalidate(productProvider(_key)),
                  ),
          ),
        ],
      ),
      data: _content,
    );
  }

  Widget _content(StoreProduct p) {
    // Deep links (/products/{id}) only know the product; the API names the page.
    final pid = widget.pageId.isEmpty ? p.pageId : widget.pageId;
    final page = pid.isEmpty ? null : ref.watch(pageProfileProvider(pid)).value;
    final favorite = ref.watch(favoritesProvider).contains(p.id);
    final max = p.stock.clamp(1, _maxPerLine);
    if (_qty > max) _qty = max;
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    final layout = _DetailsLayout.of(context);
    final wall = p.wall;
    final gallery = _Gallery(
      images: p.images,
      favorite: favorite,
      soldOut: !p.available,
      height: layout.galleryHeight,
      rounded: layout.kind != _DetailsKind.phone,
      onFavorite: () => toggleFavorite(context, ref, p.id, pid),
    );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StockLine(product: p),
        const SizedBox(height: 6),
        Text(p.name, style: AppText.big.copyWith(fontSize: 22, height: 1.45)),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            text: thousandsIqd(p.price),
            style: AppText.number.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.blue,
            ),
            children: [
              TextSpan(
                text: ' د.ع',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
        if (p.ratingCount > 0) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StarRow(value: p.rating, size: 16),
              Text(
                '${p.rating.toStringAsFixed(1)} · ${p.ratingCount} تقييم',
                style: AppText.muted.copyWith(fontSize: 13),
              ),
            ],
          ),
        ],
        if (p.sizeChoices.length > 1) ...[
          const SizedBox(height: 16),
          _VariantPicker(
            product: p,
            onPick: (v) => context.pushReplacement(Routes.product(pid, v.id)),
          ),
        ],
        if (p.hasSize) ...[const SizedBox(height: 14), _SizeLine(product: p)],
        if (wall != null) ...[
          const SizedBox(height: 12),
          WallPreviewEntry(
            size: wall,
            onTap: () => context.push(Routes.wallPreview(pid, p.id)),
          ),
        ],
        if (page != null) ...[
          const SizedBox(height: 18),
          _PageRow(
            name: page.name,
            rating: page.rating,
            deals: page.deals,
            image: page.image,
            onTap: () => context.push(Routes.pageProfile(pid)),
          ),
        ],
        const SizedBox(height: 22),
        Text('الوصف', style: AppText.strong.copyWith(fontSize: 16)),
        const SizedBox(height: 6),
        Text(
          p.description.isEmpty
              ? 'الصفحة ما كتبت وصف لهالمنتج.'
              : p.description,
          style: AppText.body.copyWith(
            height: 1.8,
            color: p.description.isEmpty ? AppColors.grey : AppColors.ink,
          ),
        ),
        ProductReviewsSection(product: p, pageId: pid),
        const SizedBox(height: 18),
        AppCard(
          flat: true,
          color: AppColors.blueTint,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSvgIcon(AppIcon.shieldCheck, color: AppColors.blue, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تدفع كاش عند الاستلام أو إلكتروني إذا متاح، وتتابع طلبك من «طلباتي». تكدر تلغيه ما دام بعده جديد.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.7,
                    color: AppColors.infoText,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Semantics(
            button: true,
            child: GestureDetector(
              onTap: () => memberOnly(context, ref, () => _report(p)),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSvgIcon(AppIcon.flag, size: 16, color: AppColors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'شي غلط بهالمنتج؟ بلّغ عليه',
                      style: AppText.muted.copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
    final top = MediaQuery.viewPaddingOf(context).top;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(productProvider(_key).future),
        child: ListView(
          padding: EdgeInsets.zero,
          children: switch (layout.kind) {
            _DetailsKind.phone => [
              gallery,
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: info,
              ),
            ],
            _DetailsKind.tablet => [
              StoreWidth(
                maxWidth: _DetailsLayout.column,
                top: top + 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [gallery, const SizedBox(height: 20), info],
                ),
              ),
              const SizedBox(height: 24),
            ],
            _DetailsKind.wide => [
              StoreWidth(
                top: top + 24,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: gallery),
                    const SizedBox(width: 36),
                    Expanded(child: info),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          },
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + inset),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: .08),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: StoreWidth(
          top: 0,
          padded: false,
          maxWidth: _DetailsLayout.column,
          child: p.available
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        QuantityStepper(
                          value: _qty,
                          max: max,
                          onChanged: (v) => setState(() => _qty = v),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          // The total joins the label only when it fits.
                          child: LayoutBuilder(
                            builder: (context, box) {
                              final scale = MediaQuery.textScalerOf(context)
                                  .scale(1);
                              final roomy = box.maxWidth / scale >= 250;
                              return AppButton(
                                _adding
                                    ? 'دا نضيف...'
                                    : roomy
                                    ? 'أضف للسلة · ${thousandsIqd(p.price * _qty)}'
                                    : 'أضف للسلة',
                                icon: _adding ? null : AppIcon.cart,
                                onPressed: _adding
                                    ? null
                                    : () => memberOnly(
                                        context,
                                        ref,
                                        () => _add(p),
                                      ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppButton(
                      ProductCard.soldOut,
                      variant: AppButtonVariant.disabled,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _add(StoreProduct p) async {
    setState(() => _adding = true);
    final ok = await addToCart(context, ref, p.id, quantity: _qty);
    if (!mounted) return;
    setState(() => _adding = false);
    if (!ok) return;
    final goCart = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => AppSheet(
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: AppSvgIcon(AppIcon.check, color: AppColors.success),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'انضاف للسلة',
            textAlign: TextAlign.center,
            style: AppText.big.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            '${p.name} × $_qty',
            textAlign: TextAlign.center,
            style: AppText.muted.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 18),
          AppButton(
            'روح للسلة',
            icon: AppIcon.cart,
            onPressed: () => Navigator.of(c).pop(true),
          ),
          const SizedBox(height: 10),
          AppButton(
            'كمّل التسوّق',
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(c).pop(false),
          ),
        ],
      ),
    );
    if (goCart == true && mounted) context.push(Routes.cart);
  }

  Future<void> _report(StoreProduct p) async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportProductSheet(productId: p.id),
    );
    if (sent == true && mounted) {
      showAppToast(context, 'وصلنا بلاغك، فريقنا يراجعه');
    }
  }
}

/// «المقاس»: the product's same-page sizes; picking one opens it.
class _VariantPicker extends StatelessWidget {
  const _VariantPicker({required this.product, required this.onPick});
  final StoreProduct product;
  final ValueChanged<ProductVariant> onPick;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('المقاس', style: AppText.strong.copyWith(fontSize: 15)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final v in product.sizeChoices)
            Semantics(
              button: true,
              selected: v.id == product.id,
              label: '${v.label}، ${storePrice(v.price)}',
              child: GestureDetector(
                onTap: v.id == product.id ? null : () => onPick(v),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: v.id == product.id
                        ? AppColors.navyFill
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: v.id == product.id
                          ? AppColors.gold
                          : AppColors.border,
                      width: v.id == product.id ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        v.label,
                        style: AppText.strong.copyWith(
                          fontSize: 13.5,
                          color: v.id == product.id
                              ? AppColors.white
                              : AppColors.ink,
                        ),
                      ),
                      Text(
                        v.available ? thousandsIqd(v.price) : 'نفدت',
                        style: AppText.number.copyWith(
                          fontSize: 12,
                          color: v.id == product.id
                              ? AppColors.goldSoft
                              : v.available
                              ? AppColors.grey
                              : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ],
  );
}

/// «الأبعاد: 145 × 83 × 6 سم».
class _SizeLine extends StatelessWidget {
  const _SizeLine({required this.product});
  final StoreProduct product;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final d = WallSize.validCm(p.depthCm) ? ' × ${cmText(p.depthCm!)}' : '';
    final tv = WallKind.parse(p.wallKind) == WallKind.tv;
    return Row(
      children: [
        AppSvgIcon(AppIcon.ruler, color: AppColors.grey, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'الأبعاد: ${cmText(p.widthCm!)} × ${cmText(p.heightCm!)}$d سم'
            '${tv ? ' · بدون الستاند' : ''}',
            style: AppText.muted.copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

enum _DetailsKind { phone, tablet, wide }

/// Details screen breakpoints: full-bleed on phones, one centered column on
/// tablets, gallery and info side by side on wide screens.
class _DetailsLayout {
  const _DetailsLayout(this.kind, this.galleryHeight);
  final _DetailsKind kind;
  final double galleryHeight;

  static const column = 720.0;

  static _DetailsLayout of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width, h = size.height;
    if (w >= 1000) {
      final col = (w.clamp(0, 1120 + 48) - 48 - 36) / 2;
      return _DetailsLayout(_DetailsKind.wide, col.clamp(320.0, h * .75));
    }
    if (w >= 700) {
      return _DetailsLayout(
        _DetailsKind.tablet,
        (column * .72).clamp(300.0, h * .5),
      );
    }
    return _DetailsLayout(_DetailsKind.phone, (w * .95).clamp(260.0, h * .52));
  }
}

/// One quiet line: category and the stock state as a coloured dot.
class _StockLine extends StatelessWidget {
  const _StockLine({required this.product});
  final StoreProduct product;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final (color, text) = !p.available
        ? (AppColors.danger, ProductCard.soldOut)
        : p.lowStock
        ? (AppColors.warn, 'باقي ${p.stock} بس')
        : (AppColors.success, 'متوفر');
    return Wrap(
      spacing: 6,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (p.category.isNotEmpty) ...[
          Text(p.category, style: AppText.muted.copyWith(fontSize: 13)),
          Text('·', style: AppText.muted),
        ],
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Text(text, style: AppText.label.copyWith(color: color, fontSize: 13)),
      ],
    );
  }
}

String thousandsIqd(int n) => storePrice(n).replaceAll(' د.ع', '');

class _PageRow extends StatelessWidget {
  const _PageRow({
    required this.name,
    required this.rating,
    required this.deals,
    required this.image,
    required this.onTap,
  });
  final String name;
  final double rating;
  final int deals;
  final String? image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: 12,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: image != null && image!.isNotEmpty
                  ? AppImage(image!, width: 44, height: 44, fit: BoxFit.cover)
                  : Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      color: AppColors.blueTint,
                      child: Text(
                        name.isEmpty ? '؟' : name.characters.first,
                        style: AppText.strong.copyWith(
                          color: AppColors.blue,
                          fontSize: 18,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.strong,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const AppSvgIcon(
                        AppIcon.verified,
                        size: 15,
                        color: AppColors.gold,
                        strokeWidth: 2.4,
                      ),
                    ],
                  ),
                  RatingLine(text: '$rating · $deals صفقة', fontSize: 12),
                ],
              ),
            ),
            Text(
              'شوف الصفحة',
              style: AppText.label.copyWith(color: AppColors.blue),
            ),
            AppSvgIcon(AppIcon.chevronLeft, size: 16, color: AppColors.blue),
          ],
        ),
      ),
    ),
  );
}

class _ReportProductSheet extends ConsumerStatefulWidget {
  const _ReportProductSheet({required this.productId});
  final String productId;

  @override
  ConsumerState<_ReportProductSheet> createState() =>
      _ReportProductSheetState();
}

class _ReportProductSheetState extends ConsumerState<_ReportProductSheet> {
  static const _reasons = [
    ('fake', 'منتج مو أصلي أو مزيّف'),
    ('mismatch', 'الصور أو الوصف مو مطابقة'),
    ('bannedItem', 'غرض ممنوع'),
    ('abuse', 'كلام مسيء'),
    ('other', 'شي ثاني'),
  ];
  final _text = TextEditingController();
  var _reason = 0;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final note = _text.text.trim();
    try {
      await ref.read(apiClientProvider).post<Object?>('/api/v1/reports', {
        'target': 'product',
        'targetId': widget.productId,
        'reason': _reasons[_reason].$1,
        'text': note.isEmpty ? _reasons[_reason].$2 : note,
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = _err(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: AppSheet(
      children: [
        Text('بلّغ على المنتج', style: AppText.big.copyWith(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          'شنو المشكلة؟ البلاغ يوصل لفريق دوّرلي، مو للصفحة.',
          style: AppText.muted,
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _reasons.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RadioRow(
              label: _reasons[i].$2,
              on: i == _reason,
              onTap: () => setState(() => _reason = i),
            ),
          ),
        TextField(
          controller: _text,
          maxLines: 2,
          maxLength: 300,
          decoration: const InputDecoration(
            hintText: 'تفاصيل إضافية (اختياري)',
          ),
        ),
        if (_error != null) ...[
          Text(_error!, style: AppText.body.copyWith(color: AppColors.danger)),
          const SizedBox(height: 8),
        ],
        AppButton(
          _busy ? 'دا نرسل...' : 'دز البلاغ',
          icon: AppIcon.flag,
          onPressed: _busy ? null : _send,
        ),
      ],
    ),
  );
}

class _DetailsSkeleton extends StatelessWidget {
  const _DetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.tabTrack,
        borderRadius: BorderRadius.circular(10),
      ),
    );
    final height = _DetailsLayout.of(context).galleryHeight;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Stack(
            children: [
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.tabTrack,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
              ),
              PositionedDirectional(
                top: MediaQuery.viewPaddingOf(context).top + 10,
                start: 14,
                child: _RoundButton(
                  icon: AppIcon.back,
                  label: 'رجوع',
                  onTap: () => popOr(context),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(80, 24),
                const SizedBox(height: 14),
                bar(220, 22),
                const SizedBox(height: 10),
                bar(120, 28),
                const SizedBox(height: 22),
                bar(double.infinity, 64),
                const SizedBox(height: 22),
                bar(double.infinity, 12),
                const SizedBox(height: 8),
                bar(240, 12),
              ],
            ),
          ),
          const LoadingBlock(),
        ],
      ),
    );
  }
}

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final parsed = cart.value == null ? null : Cart.fromJson(cart.value!);
    return AppPage(
      title: 'السلة',
      subtitle: parsed == null || parsed.isEmpty
          ? null
          : 'من «${parsed.pageName}»',
      bottom: parsed == null || parsed.isEmpty
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'المجموع',
                      style: AppText.muted.copyWith(fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      _money(parsed.subtotal),
                      style: AppText.number.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (parsed.lines.any((l) => !l.available))
                  AppButton(
                    'بالسلة منتج مو متوفر بهالكمية',
                    variant: AppButtonVariant.disabled,
                    onPressed: null,
                  )
                else
                  AppButton(
                    'كمّل الطلب',
                    onPressed: () => context.push(Routes.checkout),
                  ),
              ],
            ),
      children: [
        StoreWidth(
          maxWidth: 760,
          child: cart.when(
            loading: () => const LoadingBlock(),
            error: (e, _) => StoreMessage(
              icon: AppIcon.wifiOff,
              title: 'ما قدرنا نجيب السلة',
              body: _err(e),
              onRetry: () => ref.invalidate(cartProvider),
            ),
            data: (_) {
              final c = parsed!;
              if (c.isEmpty) {
                return const StoreMessage(
                  icon: AppIcon.cart,
                  title: 'سلتك فارغة',
                  body:
                      'افتح صفحة من الصفحات وتصفّح «المنتجات» وضيف اللي يعجبك.',
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final l in c.lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: c.pageId.isEmpty
                            ? null
                            : () => context.push(
                                Routes.product(c.pageId, l.productId),
                              ),
                        child: AppCard(
                          padding: 10,
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  color: AppColors.blueTint,
                                  alignment: Alignment.center,
                                  child: l.image.isEmpty
                                      ? AppSvgIcon(
                                          AppIcon.bag,
                                          size: 26,
                                          color: AppColors.blue.withValues(
                                            alpha: .4,
                                          ),
                                        )
                                      : AppImage(
                                          l.image,
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.strong,
                                    ),
                                    if (!l.available)
                                      Text(
                                        l.stock <= 0
                                            ? 'نفدت الكمية'
                                            : 'باقي ${l.stock} بس',
                                        style: AppText.label.copyWith(
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${l.quantity} × ${_money(l.price)}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppText.muted,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _money(l.price * l.quantity),
                                          style: AppText.number.copyWith(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        try {
                          await ref
                              .read(apiClientProvider)
                              .delete<Object?>('/api/v1/store/cart');
                        } catch (e) {
                          if (context.mounted) {
                            showAppToast(context, _err(e), icon: AppIcon.alert);
                          }
                        }
                        ref.invalidate(cartProvider);
                      },
                      icon: AppSvgIcon(
                        AppIcon.trash,
                        size: 16,
                        color: AppColors.danger,
                      ),
                      label: Text(
                        'فرّغ السلة',
                        style: AppText.label.copyWith(color: AppColors.danger),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
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
  final _note = TextEditingController();
  LatLng? _pin;
  String _pay = 'cash';
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final p = await pickDeliveryPin(context, initial: _pin);
    if (p != null && mounted) setState(() => _pin = p);
  }

  Future<void> _submit() async {
    if (_address.text.trim().isEmpty) {
      setState(() => _error = 'اكتب العنوان');
      return;
    }
    if (PostRules.hasContactInfo(_address.text) ||
        PostRules.hasContactInfo(_note.text)) {
      setState(() => _error = storeErrorText['order.contact']);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final j = await ref.read(apiClientProvider).post<Map<String, dynamic>>(
        '/api/v1/store/orders',
        {
          'address': _address.text.trim(),
          'paymentMethod': _pay,
          if (_pin case final p?) ...{
            'latitude': p.latitude,
            'longitude': p.longitude,
          },
          if (_note.text.trim().isNotEmpty) 'locationNote': _note.text.trim(),
        },
      );
      ref.invalidate(cartProvider);
      ref.invalidate(storeOrdersProvider);
      ref.invalidate(storeOrderProvider);
      final id = (j['orderId'] ?? j['id']) as String;
      if (mounted) context.go(Routes.storeOrder(id));
    } on ApiException catch (e) {
      // Electronic payment off on the server: fall back to cash so the
      // customer can confirm again in one tap.
      if (e.code == 'payment.not_configured') _pay = 'cash';
      // Stock, availability or the cart changed since it was loaded.
      if (e.status == 409 || e.status == 422 || e.code.startsWith('product.')) {
        ref.invalidate(cartProvider);
      }
      if (mounted) setState(() => _error = _err(e));
    } catch (e) {
      if (mounted) setState(() => _error = _err(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _StorePage(
      title: 'إكمال الطلب',
      bottom: AppButton(
        _busy ? '...' : 'تأكيد الطلب',
        onPressed: _busy ? null : _submit,
      ),
      children: [
        TextField(
          controller: _address,
          decoration: const InputDecoration(labelText: 'العنوان'),
          maxLength: 300,
        ),
        if (_pin case final p?) ...[
          OrderPinMap(
            latitude: p.latitude,
            longitude: p.longitude,
            height: 130,
          ),
          const SizedBox(height: 6),
        ],
        AppButton(
          _pin == null ? 'حدد موقعك على الخريطة (اختياري)' : 'غيّر الدبوس',
          compact: true,
          icon: AppIcon.pin,
          variant: AppButtonVariant.ghost,
          onPressed: _pick,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _note,
          decoration: const InputDecoration(
            labelText: 'ملاحظة للمندوب (اختياري)',
          ),
          maxLength: 200,
        ),
        const SizedBox(height: 12),
        RadioGroup<String>(
          groupValue: _pay,
          onChanged: (v) => setState(() => _pay = v ?? _pay),
          child: Column(
            children: const [
              RadioListTile<String>(
                value: 'cash',
                title: Text('كاش عند الاستلام'),
              ),
              RadioListTile<String>(
                value: 'electronic',
                title: Text('دفع إلكتروني'),
              ),
            ],
          ),
        ),
        if (_error != null)
          Text(_error!, style: AppText.body.copyWith(color: AppColors.danger)),
      ],
    );
  }
}

/// «المفضلة»: hearted products in the same card grid.
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

/// «المفضلة»: chips الكل / متوفر / نفدت over the hearted products.
class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  static const _filters = ['الكل', 'متوفر', 'نفدت'];
  var _filter = 0;

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(favoriteProductsProvider);
    final cart = ref.watch(cartSummaryProvider);
    final items = list.value ?? const <FavoriteProduct>[];
    final available = items.where((f) => f.product.available).length;
    final counts = [items.length, available, items.length - available];
    final shown = [
      for (final f in items)
        if (_filter == 0 || (_filter == 1) == f.product.available) f,
    ];
    return AppPage(
      title: 'المفضلة',
      subtitle: items.isEmpty
          ? 'المنتجات اللي حطيت عليها قلب'
          : '${items.length} منتج حطيت عليه قلب',
      onRefresh: () => ref.refresh(favoriteProductsProvider.future),
      bottom: cart.isEmpty
          ? null
          : StoreWidth(
              top: 0,
              padded: false,
              maxWidth: 760,
              child: CartBar(
                cart: cart,
                onTap: () => context.push(Routes.cart),
              ),
            ),
      children: [
        StoreWidth(
          child: list.when(
            skipLoadingOnReload: true,
            loading: () => const ProductGrid(items: [], skeleton: 4),
            error: (e, _) => StoreMessage(
              icon: AppIcon.wifiOff,
              title: 'ما قدرنا نجيب المفضلة',
              body: 'تأكد من النت وجرّب مرة ثانية.',
              onRetry: () => ref.invalidate(favoriteProductsProvider),
            ),
            data: (_) => items.isEmpty
                ? const _FavoritesEmpty()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < _filters.length; i++)
                            AppChip(
                              '${_filters[i]} · ${counts[i]}',
                              selected: _filter == i,
                              onTap: () => setState(() => _filter = i),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (shown.isEmpty)
                        StoreMessage(
                          icon: AppIcon.heart,
                          title: _filter == 1
                              ? 'كل مفضلتك نفدت هسه'
                              : 'كل مفضلتك متوفرة',
                          body: _filter == 1
                              ? 'من ترجع الكمية تكدر تطلبها مباشرة.'
                              : 'ماكو منتج نفدت كميته من مفضلتك.',
                        )
                      else
                        ProductGrid(
                          items: [
                            for (final f in shown)
                              ProductCardData(
                                id: f.product.id,
                                pageId: f.pageId,
                                name: f.product.name,
                                description: f.product.description,
                                price: f.product.price,
                                image: f.product.image,
                                available: f.product.available,
                                stock: f.product.stock,
                                caption: f.pageName.isEmpty ? null : f.pageName,
                                rating: f.product.rating,
                                ratingCount: f.product.ratingCount,
                              ),
                          ],
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _FavoritesEmpty extends StatelessWidget {
  const _FavoritesEmpty();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 36),
    child: Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.blueTint,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: AppSvgIcon(
            AppIcon.heart,
            color: AppColors.blue,
            size: 42,
            strokeWidth: 1.8,
          ),
        ),
        const SizedBox(height: 18),
        Text('ما عندك مفضلة بعد', style: AppText.big.copyWith(fontSize: 19)),
        const SizedBox(height: 6),
        Text(
          'دوس القلب على أي منتج يعجبك، ويطلعلك هنا حتى ترجعله بسهولة.',
          textAlign: TextAlign.center,
          style: AppText.muted.copyWith(fontSize: 14, height: 1.7),
        ),
        const SizedBox(height: 20),
        AppButton(
          'تصفّح الأكثر مبيعاً',
          icon: AppIcon.bag,
          onPressed: () => context.push(Routes.ranking('best-selling')),
        ),
        const SizedBox(height: 10),
        AppButton(
          'شوف الصفحات',
          icon: AppIcon.store,
          variant: AppButtonVariant.ghost,
          onPressed: () => context.go(Routes.pages),
        ),
      ],
    ),
  );
}
